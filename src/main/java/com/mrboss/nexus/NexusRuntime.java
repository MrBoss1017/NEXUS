package com.mrboss.nexus;

import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.server.permissions.Permissions;
import net.minecraft.world.BossEvent;
import net.minecraft.world.entity.*;
import net.minecraft.world.entity.monster.Monster;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.level.gamerules.GameRules;
import net.minecraft.world.phys.*;
import java.util.*;

/** All mutations run on the server thread. One bounded scheduler replaces thousands of Luau coroutines. */
public final class NexusRuntime {
    @FunctionalInterface public interface Effect { boolean tick(int age); }
    private record Job(NexusSession owner, int generation, long start, int lifetime, Effect effect) {}
    private record Burn(NexusSession owner, LivingEntity victim, long until) {}
    public final MinecraftServer server;
    public final Random random = new Random();
    public final NexusFx fx = new NexusFx(this);
    public final NexusMinions minions = new NexusMinions(this);
    private NexusConfig config;
    private final Map<UUID, NexusSession> sessions = new LinkedHashMap<>();
    private final List<Job> jobs = new ArrayList<>(), pending = new ArrayList<>();
    private final Map<UUID, Burn> burns = new HashMap<>();
    private final Map<UUID, Long> stomps = new HashMap<>();
    private long now;
    private int processingJobs;
    public long damageEvents, failedEffects;
    public NexusRuntime(MinecraftServer server, NexusConfig config) { this.server = server; this.config = config; }
    public NexusConfig config() { return config; }
    public long now() { return now; }
    public Collection<NexusSession> sessions() { return List.copyOf(sessions.values()); }
    public NexusSession session(LivingEntity actor) { return sessions.get(actor.getUUID()); }
    public int effectCount() { return jobs.size() + pending.size() + processingJobs; }
    public void reload() throws Exception { config = NexusConfig.read(NexusMod.CONFIG_PATH); }
    public static void tell(LivingEntity entity, String text) {
        if (entity instanceof ServerPlayer player) player.sendOverlayMessage(Component.literal(text));
    }
    public boolean canActivate(ServerPlayer player) {
        return !config.requireCore || player.isCreative() || player.permissions().hasPermission(Permissions.COMMANDS_GAMEMASTER)
            || player.getInventory().contains(new net.minecraft.world.item.ItemStack(NexusItems.CORE));
    }
    public void useCore(ServerPlayer player, boolean conduit) {
        if (session(player) == null) { if (conduit || canActivate(player)) activate(player, conduit); }
        else if (player.isShiftKeyDown()) deactivate(player);
        else NexusMenu.open(player);
    }
    public boolean activate(LivingEntity actor, boolean bypassCore) {
        if (!(actor.level() instanceof ServerLevel) || !actor.isAlive() || actor.isSpectator()) return false;
        if (session(actor) != null) { tell(actor, "You already wield the Nexus."); return false; }
        if (actor instanceof ServerPlayer p && !bypassCore && !canActivate(p)) { tell(p, "Carry a Nexus Core to awaken."); return false; }
        if (config.singleBoss && !sessions.isEmpty()) { tell(actor, "Another Nexus is already awakened."); return false; }
        minions.release(actor.getUUID(), false);
        var s = new NexusSession(actor, config, now); sessions.put(actor.getUUID(), s);
        intro(s); tell(actor, "Nexus awakened. Use the Core again for controls; sneak-use to release."); return true;
    }
    public void intro(NexusSession s) {
        if (s.current != null) return;
        s.busyUntil = Math.max(s.busyUntil, now + config.introTicks);
        taunt(s, "Mortals... you dare awaken the NEXUS?");
        schedule(s, 0, config.introTicks, age -> {
            if (age % 4 == 0) {
                fx.helix(s.level, s.actor.position(), 1.5 + age * .025, 4, age * .12, 0xAA55FF);
                if (age % 20 == 0) fx.ring(s.level, s.actor.position(), 2 + age * .04, 0xBB88FF);
            }
            return true;
        });
    }
    public void taunt(NexusSession s, String text) {
        if (!config.taunts) return;
        for (ServerPlayer p : s.level.players())
            if (p.distanceToSqr(s.actor) < 128 * 128) p.sendSystemMessage(Component.literal("NEXUS · " + text));
    }
    public void deactivate(LivingEntity actor) {
        NexusSession s = sessions.remove(actor.getUUID());
        if (s == null) return;
        taunt(s, actor.isAlive() ? "The Nexus rests... for now." : "This is not... the end...");
        minions.clear(s); s.restore();
        jobs.removeIf(j -> j.owner == s); pending.removeIf(j -> j.owner == s);
        burns.values().removeIf(b -> b.owner == s); stomps.clear();
        fx.burst(s.level, actor.position(), 3, 0xCC99FF);
        if (actor instanceof Mob && actor.entityTags().contains("nexus_ephemeral")) actor.discard();
    }
    public void leave(LivingEntity actor) { deactivate(actor); minions.release(actor.getUUID(), false); burns.remove(actor.getUUID()); }
    public void stopAll() { for (NexusSession s : sessions()) deactivate(s.actor); jobs.clear(); pending.clear(); burns.clear(); }
    public boolean cast(LivingEntity actor, Ability ability) {
        NexusSession s = session(actor);
        if (s == null) { tell(actor, "Awaken using a Nexus Core first."); return false; }
        NexusConfig.Power power = config.power(ability);
        if (!power.enabled() || ability == Ability.NEXUS_FINALE && !config.finaleEnabled) { tell(actor, "This power is disabled."); return false; }
        if (now < s.busyUntil || NexusStatus.immobilized(actor)) { tell(actor, "A cast is already in progress, or you are immobilized."); return false; }
        int duration = ability == Ability.NEXUS_FINALE ? FinaleTimeline.PHASES.size() * config.finalePhaseTicks : Math.max(power.duration(), power.windup() + 20);
        if (!s.cooldowns.acquire(ability, now, config.globalCooldown, duration, power.cooldown())) {
            tell(actor, ability.title + " · " + String.format(Locale.ROOT, "%.1fs", s.cooldowns.remaining(ability, now) / 20.0) + " remaining"); return false;
        }
        s.current = ability; s.busyUntil = now + duration;
        if (ability == Ability.NEXUS_FINALE) FinaleTimeline.start(this, s);
        else AbilityEngine.start(this, s, ability, power, duration);
        return true;
    }
    public void cancel(NexusSession s) {
        if (s.current == Ability.NEXUS_FINALE) {
            s.recruitment = s.finalePreviousRecruitment;
            if (!s.recruitment) minions.clear(s);
        }
        s.generation++; s.current = null; s.phase = 0; s.busyUntil = now + config.globalCooldown;
        jobs.removeIf(j -> j.owner == s); pending.removeIf(j -> j.owner == s); minions.clearNpcs(s);
        s.bar.setDarkenScreen(false);
    }
    public void schedule(NexusSession owner, int delay, int lifetime, Effect effect) {
        if (effectCount() >= config.maxEffects || !owner.valid()) return;
        // Pending jobs enter the active queue on the next tick. Delay zero must
        // start then, otherwise a one-tick callback would expire before running.
        pending.add(new Job(owner, owner.generation, now + Math.max(1, delay), Math.max(1, lifetime), effect));
    }
    public void later(NexusSession owner, int delay, Runnable effect) {
        schedule(owner, delay, 1, age -> { effect.run(); return false; });
    }
    public void tick() {
        now++; fx.reset();
        jobs.addAll(pending); pending.clear();
        // Process a snapshot, so entity death/unload can cancel jobs synchronously and safely.
        List<Job> active = new ArrayList<>(jobs); jobs.clear();
        processingJobs = active.size();
        for (Job job : active) {
            processingJobs--;
            if (!job.owner.valid() || job.owner.generation != job.generation) continue;
            int age = (int)(now - job.start);
            try {
                boolean keep = age < 0 || age < job.lifetime && job.effect.tick(age);
                if (keep && job.owner.valid() && job.owner.generation == job.generation) jobs.add(job);
            } catch (RuntimeException ex) {
                failedEffects++; NexusMod.LOG.error("Nexus effect failed; cancelled the cast", ex); cancel(job.owner);
            }
        }
        for (Burn burn : List.copyOf(burns.values())) {
            if (!burn.owner.valid() || !burn.victim.isAlive() || now >= burn.until) burns.remove(burn.victim.getUUID());
            else if (now % config.burnInterval == 0) {
                damage(burn.owner, burn.victim, config.burnDamage, false);
                fx.particle(burn.owner.level, net.minecraft.core.particles.ParticleTypes.FLAME, burn.victim.position().add(0, 1, 0), 3, .3);
            }
        }
        minions.tick();
        for (NexusSession s : sessions()) {
            if (!s.valid()) { deactivate(s.actor); continue; }
            if (now >= s.busyUntil && s.current != null) { s.current = null; s.phase = 0; s.bar.setDarkenScreen(false); }
            if (now % 10 == 0) update(s);
            if (now % 5 == 0 && s.ai && now >= s.busyUntil && now >= s.nextAi) ai(s);
        }
    }
    private void update(NexusSession s) {
        s.bar.setName(Component.literal("NEXUS · " + (int)s.actor.getHealth() + "/" + (int)s.actor.getMaxHealth()
            + (s.phase > 0 ? " · Phase " + s.phase + "/34" : s.current != null ? " · " + s.current.title : " · Awakened")));
        s.bar.setProgress(Math.clamp(s.actor.getHealth() / s.actor.getMaxHealth(), 0, 1));
        s.bar.setColor(s.bar.getProgress() > .6 ? BossEvent.BossBarColor.PURPLE : s.bar.getProgress() > .3 ? BossEvent.BossBarColor.YELLOW : BossEvent.BossBarColor.RED);
        Set<ServerPlayer> nearby = new HashSet<>();
        for (ServerPlayer p : s.level.players()) if (p.distanceToSqr(s.actor) < 128 * 128) nearby.add(p);
        for (ServerPlayer p : List.copyOf(s.bar.getPlayers())) if (!nearby.contains(p)) s.bar.removePlayer(p);
        nearby.forEach(s.bar::addPlayer);
        fx.helix(s.level, s.actor.position(), .75, 2.2, now * .1, 0x9955FF);
        for (ServerPlayer p : nearby) {
            if (!enemy(s, p) || p.onGround() || p.getDeltaMovement().y >= -.05) continue;
            double height = p.getY() - (s.actor.getY() + s.actor.getBbHeight());
            double dx = p.getX() - s.actor.getX(), dz = p.getZ() - s.actor.getZ();
            if (dx*dx + dz*dz < 2.25 && height >= -.5 && height <= 1.5 && now >= stomps.getOrDefault(p.getUUID(), 0L)) {
                s.actor.hurtServer(s.level, s.actor.damageSources().playerAttack(p), (float)config.stompDamage);
                stomps.put(p.getUUID(), now + config.stompCooldown); p.setDeltaMovement(p.getDeltaMovement().add(0, .55, 0)); p.syncVelocity = true;
                tell(p, "Nexus stomp! " + config.stompDamage + " damage");
            }
        }
    }
    private void ai(NexusSession s) {
        LivingEntity target = nearest(s, s.actor.position(), config.detectionRange);
        if (target == null) return;
        s.actor.lookAt(net.minecraft.commands.arguments.EntityAnchorArgument.Anchor.EYES, target.getEyePosition());
        if (s.actor.distanceToSqr(target) > config.attackRange * config.attackRange) {
            Vec3 dir = target.position().subtract(s.actor.position()).multiply(1, 0, 1).normalize().scale(config.aiSpeed);
            if (s.actor instanceof Mob mob) mob.getNavigation().moveTo(target, 1.1);
            else { s.actor.setDeltaMovement(dir.x, s.actor.getDeltaMovement().y, dir.z); s.actor.syncVelocity = true; }
            return;
        }
        s.nextAi = now + config.aiInterval;
        List<Ability> available = Arrays.stream(Ability.values()).filter(a -> a != Ability.NEXUS_FINALE && config.power(a).enabled()
            && s.cooldowns.remaining(a, now) == 0).toList();
        if (!available.isEmpty()) cast(s.actor, available.get(random.nextInt(available.size())));
    }
    public boolean enemy(NexusSession s, LivingEntity target) {
        if (!target.isAlive() || target.isRemoved() || target == s.actor || target.isSpectator() || target.level() != s.level
            || minions.allied(s, target) || s.actor.isAlliedTo(target)) return false;
        if (target instanceof Player p) return config.pvp && !p.isCreative() && s.level.getGameRules().get(GameRules.PVP)
            && (!(s.actor instanceof Player actor) || actor.canHarmPlayer(p));
        return target instanceof Monster ? config.targetMobs : config.targetAnimals;
    }
    public List<LivingEntity> targets(NexusSession s, Vec3 point, double radius) {
        return s.level.getEntitiesOfClass(LivingEntity.class, new AABB(point, point).inflate(radius), e -> enemy(s, e))
            .stream().filter(e -> e.position().distanceToSqr(point) <= radius*radius)
            .sorted(Comparator.comparingDouble(e -> e.position().distanceToSqr(point))).limit(config.maxTargets).toList();
    }
    public LivingEntity nearest(NexusSession s, Vec3 point, double radius) { return targets(s, point, radius).stream().findFirst().orElse(null); }
    public void damage(NexusSession owner, LivingEntity target, double sourceDamage, boolean directSource) {
        if (!owner.valid() || !enemy(owner, target) || sourceDamage <= 0) return;
        float amount = (float)(sourceDamage * config.damageScale * (directSource ? 1 : config.sourceMultiplier));
        if (target.hurtServer(owner.level, target.damageSources().indirectMagic(owner.actor, owner.actor), amount)) damageEvents++;
    }
    public void aoe(NexusSession s, Vec3 center, double radiusSource, double damageSource, double knockbackSource, NexusStatus.Kind status) {
        double radius = Math.max(.3, Math.min(100, radiusSource * config.rangeScale));
        for (LivingEntity target : targets(s, center, radius)) {
            double falloff = Math.max(0, 1 - target.position().distanceTo(center)/radius);
            if (falloff <= 0) continue;
            damage(s, target, damageSource * falloff, false);
            if (target.isAlive()) NexusStatus.apply(this, s, target, status);
            if (knockbackSource > 0) {
                Vec3 direction = target.position().subtract(center).normalize();
                double strength = Math.min(2, knockbackSource * config.knockbackScale);
                target.push(direction.x * strength, strength / 3, direction.z * strength); target.syncVelocity = true;
            }
        }
        if (config.blockDamage) {
            // Explicit opt-in, small bounded blast; never deletes block entities or unbreakable blocks.
            BlockPos origin = BlockPos.containing(center);
            for (BlockPos pos : BlockPos.betweenClosed(origin.offset(-2,-1,-2), origin.offset(2,1,2))) {
                var state = s.level.getBlockState(pos);
                if (s.level.hasChunkAt(pos) && s.level.getWorldBorder().isWithinBounds(pos) && !state.isAir()
                    && state.getDestroySpeed(s.level, pos) >= 0 && !state.hasBlockEntity()) s.level.destroyBlock(pos, true, s.actor);
            }
        }
    }
    public void pull(NexusSession s, Vec3 point, double radius, double force, double lift) {
        for (LivingEntity target : targets(s, point, radius)) {
            Vec3 v = point.subtract(target.position()).normalize().scale(force);
            target.setDeltaMovement(target.getDeltaMovement().scale(.7).add(v).add(0,lift,0)); target.syncVelocity = true;
        }
    }
    public Vec3 aim(NexusSession s) {
        LivingEntity nearest = s.ai ? nearest(s, s.actor.position(), config.attackRange) : null;
        if (nearest != null) return nearest.position();
        Vec3 eye = s.actor.getEyePosition(), end = eye.add(s.actor.getLookAngle().scale(config.attackRange));
        HitResult hit = s.level.clip(new ClipContext(eye, end, ClipContext.Block.COLLIDER, ClipContext.Fluid.NONE, s.actor));
        return hit.getType() == HitResult.Type.MISS ? s.actor.position().add(s.actor.getLookAngle().multiply(1,0,1).normalize().scale(10)) : hit.getLocation().add(0,.15,0);
    }
    public Vec3 ground(NexusSession s, Vec3 p) {
        if (!s.level.hasChunkAt(BlockPos.containing(p))) return s.actor.position();
        var hit = s.level.clip(new ClipContext(p.add(0,16,0), p.add(0,-32,0), ClipContext.Block.COLLIDER, ClipContext.Fluid.NONE, s.actor));
        return hit.getType() == HitResult.Type.MISS ? p : hit.getLocation().add(0,.1,0);
    }
    public void burn(NexusSession s, LivingEntity target) { burns.put(target.getUUID(), new Burn(s, target, now + config.statusBurnTicks)); }
    public boolean blockHealing(LivingEntity entity) {
        return !config.naturalHealing && (session(entity) != null || minions.infected(entity));
    }
}
