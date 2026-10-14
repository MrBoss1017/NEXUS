package com.mrboss.nexus;

import java.util.EnumMap;

/** Server tick based; system clock changes and forged client timestamps cannot bypass it. */
public final class CooldownGate {
    private final EnumMap<Ability, Long> ready = new EnumMap<>(Ability.class);
    private long globalReady;
    public long remaining(Ability ability, long tick) {
        return Math.max(0, Math.max(globalReady, ready.getOrDefault(ability, 0L)) - tick);
    }
    public boolean acquire(Ability ability, long tick, int globalTicks, int durationTicks, int cooldownTicks) {
        if (remaining(ability, tick) > 0) return false;
        globalReady = tick + globalTicks;
        // The original records its attack timestamp after the attack finishes.
        ready.put(ability, tick + durationTicks + cooldownTicks);
        return true;
    }
}
