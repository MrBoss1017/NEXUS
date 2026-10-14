package com.mrboss.nexus;

import org.tomlj.Toml;
import org.tomlj.TomlParseResult;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.EnumMap;
import java.util.List;

/** Validated immutable snapshot. Reload swaps this only after the whole file passes validation. */
public final class NexusConfig {
    public record Power(boolean enabled, double damage, double radius, double knockback,
                        int duration, int cooldown, int windup, int pulses,
                        double finisherDamage, double finisherRadius, double lingeringDamage) {}
    private final TomlParseResult data;
    public final EnumMap<Ability, Power> powers = new EnumMap<>(Ability.class);
    public final double damageScale, sourceMultiplier, rangeScale, knockbackScale, bossHealth;
    public final boolean singleBoss, requireCore, pvp, targetMobs, targetAnimals, blockDamage, naturalHealing;
    public final int globalCooldown, maxEffects, maxParticles, maxTargets, maxNpcs, maxMinions;
    public final double detectionRange, attackRange, aiSpeed, contactRange;
    public final int aiInterval, recruitCooldown, minionInterval, npcLifetime, introTicks, finalePhaseTicks;
    public final boolean recruitPlayers, recruitMobs, infectionEnabled, finaleEnabled, taunts;
    public final double npcHealthScale, npcDamageScale, minionHeal, weaknessMultiplier, stompDamage;
    public final int stompCooldown, statusBurnTicks, burnInterval, stunTicks, freezeTicks, slowTicks, blindTicks, levitateTicks, weaknessTicks;
    public final double burnDamage;
    public final float volume;
    public final List<String> autoActivate;

    private NexusConfig(TomlParseResult d) {
        data = d;
        if (d.hasErrors()) throw new IllegalArgumentException("Invalid nexus.toml: " + d.errors());
        if (integer("general.schema_version", 1, 1, 1) != 1) throw new IllegalArgumentException("Unsupported schema");
        bossHealth = number("general.boss_health", 600, 20, 1024);
        damageScale = number("general.damage_scale", .02, 0, 10);
        sourceMultiplier = number("general.source_damage_multiplier", 2, 0, 10);
        rangeScale = number("general.range_scale", .1, .01, 1);
        knockbackScale = number("general.knockback_scale", .008, 0, .1);
        singleBoss = bool("general.single_boss", true);
        requireCore = bool("general.require_core", true);
        pvp = bool("general.affect_players", true);
        targetMobs = bool("general.affect_hostile_mobs", true);
        targetAnimals = bool("general.affect_passive_mobs", false);
        blockDamage = bool("general.break_blocks", false);
        naturalHealing = bool("general.allow_boss_healing", false);
        globalCooldown = integer("general.global_cooldown_ticks", 6, 1, 1200);
        introTicks = integer("general.intro_ticks", 100, 1, 2400);
        taunts = bool("visuals.taunts", true);
        volume = (float)number("visuals.sound_volume", .3, 0, 1);
        maxParticles = integer("performance.particles_per_tick", 384, 0, 4096);
        maxEffects = integer("performance.max_effects", 256, 16, 2048);
        maxTargets = integer("performance.max_targets_per_hit", 64, 1, 512);
        maxNpcs = integer("performance.max_npcs", 24, 1, 100);
        maxMinions = integer("performance.max_minions", 32, 1, 128);
        detectionRange = number("ai.detection_range_blocks", 40, 1, 128);
        attackRange = number("ai.attack_range_blocks", 24, 1, 64);
        aiSpeed = number("ai.movement_speed", .22, .01, .6);
        aiInterval = integer("ai.attack_interval_ticks", 16, 1, 1200);
        recruitPlayers = bool("minions.recruit_players", true);
        recruitMobs = bool("minions.recruit_mobs", true);
        contactRange = number("minions.contact_range_blocks", 1.3, .1, 4);
        recruitCooldown = integer("minions.recruit_cooldown_ticks", 20, 1, 1200);
        minionInterval = integer("minions.support_interval_ticks", 100, 10, 2400);
        minionHeal = number("minions.support_heal", 1, 0, 100);
        npcLifetime = integer("minions.npc_lifetime_ticks", 2400, 40, 24000);
        npcHealthScale = number("minions.npc_health_scale", .1, .001, .6);
        npcDamageScale = number("minions.npc_damage_scale", 1, 0, 20);
        infectionEnabled = bool("infection.enabled", true);
        finaleEnabled = bool("finale.enabled", true);
        finalePhaseTicks = integer("finale.phase_ticks", 360, 20, 2400);
        weaknessMultiplier = number("status.vulnerability_multiplier", 1.5, 1, 10);
        statusBurnTicks = integer("status.burn_ticks", 80, 1, 2400);
        burnInterval = integer("status.burn_interval_ticks", 10, 1, 200);
        burnDamage = number("status.burn_source_damage", 5, 0, 1000);
        stunTicks = integer("status.stun_ticks", 40, 1, 1200);
        freezeTicks = integer("status.freeze_ticks", 60, 1, 1200);
        slowTicks = integer("status.slow_ticks", 100, 1, 1200);
        blindTicks = integer("status.blind_ticks", 80, 1, 1200);
        levitateTicks = integer("status.levitate_ticks", 60, 1, 1200);
        weaknessTicks = integer("status.vulnerability_ticks", 120, 1, 2400);
        stompDamage = number("stomp.damage", 9, 0, 1024);
        stompCooldown = integer("stomp.cooldown_ticks", 800, 1, 12000);
        var ids = d.getArray("general.auto_activate_uuids");
        autoActivate = ids == null ? List.of() : ids.toList().stream().map(x -> {
            java.util.UUID.fromString(x.toString()); return x.toString();
        }).toList();
        for (Ability a : Ability.values()) {
            String k = "abilities." + a.id() + ".";
            powers.put(a, new Power(bool(k + "enabled", true), number(k + "damage", a.damage, 0, 20000),
                number(k + "radius", a.radius, 1, 1000), number(k + "knockback", a.knockback, 0, 2000),
                integer(k + "duration_ticks", a.duration, 40, 120000), integer(k + "cooldown_ticks", a == Ability.NEXUS_FINALE ? 2400 : 40, 0, 120000),
                integer(k + "windup_ticks", 40, 1, 1200), integer(k + "pulses", 8, 1, 64),
                number(k + "finisher_damage", a.damage * 1.6, 0, 20000), number(k + "finisher_radius", a.radius * 1.4, 1, 1000),
                number(k + "lingering_damage", a.damage * .15, 0, 5000)));
        }
    }
    public static NexusConfig read(Path path) throws IOException {
        if (!Files.exists(path)) {
            Files.createDirectories(path.getParent());
            try (InputStream in = NexusConfig.class.getResourceAsStream("/nexus-default.toml")) {
                if (in == null) throw new IOException("Missing packaged default configuration");
                Files.copy(in, path);
            }
        }
        return parse(Files.readString(path));
    }
    public static NexusConfig parse(String text) { return new NexusConfig(Toml.parse(text)); }
    public Power power(Ability a) { return powers.get(a); }
    private boolean bool(String key, boolean fallback) {
        Object value = data.get(key);
        if (value == null) return fallback;
        if (!(value instanceof Boolean b)) throw new IllegalArgumentException(key + " must be true or false");
        return b;
    }
    private double number(String key, double fallback, double min, double max) {
        Object value = data.get(key);
        if (value == null) return fallback;
        if (!(value instanceof Number n)) throw new IllegalArgumentException(key + " must be numeric");
        double v = n.doubleValue();
        if (!Double.isFinite(v) || v < min || v > max) throw new IllegalArgumentException(key + " must be in [" + min + ", " + max + "]");
        return v;
    }
    private int integer(String key, int fallback, int min, int max) {
        double d = number(key, fallback, min, max);
        if (d != Math.rint(d)) throw new IllegalArgumentException(key + " must be an integer");
        return (int)d;
    }
}
