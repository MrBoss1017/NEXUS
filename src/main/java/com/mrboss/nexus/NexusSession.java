package com.mrboss.nexus;

import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerBossEvent;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.BossEvent;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.ai.attributes.Attributes;

/** A single possession. No player statistics or ownership references survive its termination. */
public final class NexusSession {
    public final LivingEntity actor;
    public final ServerLevel level;
    public final CooldownGate cooldowns = new CooldownGate();
    public final ServerBossEvent bar = new ServerBossEvent(java.util.UUID.randomUUID(), Component.literal("NEXUS"), BossEvent.BossBarColor.PURPLE, BossEvent.BossBarOverlay.PROGRESS);
    public final float previousHealth;
    public boolean ai, recruitment, infection, closing, finalePreviousRecruitment;
    public long busyUntil, nextAi;
    public int phase, generation;
    public Ability current;
    public NexusSession(LivingEntity actor, NexusConfig config, long now) {
        this.actor = actor; this.level = (ServerLevel) actor.level(); previousHealth = actor.getHealth();
        var attribute = actor.getAttribute(Attributes.MAX_HEALTH);
        if (attribute == null) throw new IllegalArgumentException("Actor lacks max health");
        attribute.removeModifier(NexusMod.id("boss_health"));
        attribute.addTransientModifier(new AttributeModifier(NexusMod.id("boss_health"), Math.max(0, config.bossHealth - actor.getMaxHealth()), AttributeModifier.Operation.ADD_VALUE));
        actor.setHealth(actor.getMaxHealth());
        busyUntil = now + config.introTicks;
    }
    public boolean valid() { return !closing && actor.isAlive() && !actor.isRemoved() && actor.level() == level; }
    public void restore() {
        closing = true; generation++; bar.removeAllPlayers();
        var attribute = actor.getAttribute(Attributes.MAX_HEALTH);
        if (attribute != null) attribute.removeModifier(NexusMod.id("boss_health"));
        // Do not heal on release; keep damage, capped at the restored maximum.
        if (actor.isAlive()) actor.setHealth(Math.min(actor.getHealth(), actor.getMaxHealth()));
    }
}
