package com.mrboss.nexus;

import java.util.Locale;

/** Order is the source script's AllAttacks order, including the final entry. */
public enum Ability {
    LIGHTNING_STRIKE("Lightning Strike", 0xFFFF99, 220, 45, 100, 200),
    METEOR_SHOWER("Meteor Shower", 0xFF6633, 280, 50, 120, 220),
    DIMENSIONAL_RIFTS("Dimensional Rifts", 0x9922FF, 180, 25, 80, 220),
    ARCANE_DEVASTATION("Arcane Devastation", 0xBB55FF, 240, 35, 100, 220),
    INFERNO_TORNADO("Inferno Tornado", 0xFF5500, 60, 30, 60, 200),
    COSMIC_ANNIHILATION("Cosmic Annihilation", 0xBB99FF, 200, 45, 80, 240),
    QUANTUM_SLICE("Quantum Slice", 0x55FF99, 180, 70, 70, 160),
    STELLAR_CONVERGENCE("Stellar Convergence", 0xFFCC44, 85, 25, 40, 240),
    VOID_STORM("Void Storm", 0x663399, 90, 30, 50, 240),
    PLASMA_NOVA("Plasma Nova", 0x33EEFF, 180, 100, 80, 200),
    CRYO_BLAST("Cryo Blast", 0xBBEEFF, 60, 25, 20, 180),
    GRAVITY_COLLAPSE("Gravity Collapse", 0x8822CC, 100, 50, 250, 180),
    PLASMA_CASCADE("Plasma Cascade", 0xFF33DD, 95, 30, 50, 240),
    REALITY_SHATTER("Reality Shatter", 0xFF55BB, 45, 35, 20, 200),
    SOLAR_FLARE_BURST("Solar Flare Burst", 0xFFDD55, 120, 14, 50, 160),
    TEMPORAL_DISTORTION("Temporal Distortion", 0x55FFCC, 20, 35, 0, 240),
    VOLCANIC_ERUPTION("Volcanic Eruption", 0xFF3300, 150, 25, 70, 200),
    ANTIMATTER_ANNIHILATION("Antimatter Annihilation", 0xCCEEFF, 250, 120, 120, 220),
    TYPHOON_CYCLONE("Typhoon Cyclone", 0xCCDDEE, 30, 30, 40, 180),
    NEXUS_FINALE("Nexus Finale", 0xFF44FF, 320, 35, 130, 12000);

    public final String title;
    public final int color, duration;
    public final double damage, radius, knockback;

    Ability(String title, int color, double damage, double radius, double knockback, int duration) {
        this.title = title; this.color = color; this.damage = damage;
        this.radius = radius; this.knockback = knockback; this.duration = duration;
    }
    public String id() { return name().toLowerCase(Locale.ROOT); }
}
