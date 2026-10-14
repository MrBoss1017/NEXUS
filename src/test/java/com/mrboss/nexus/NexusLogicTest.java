package com.mrboss.nexus;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class NexusLogicTest {
    @Test void cooldownIncludesCastAndRecoveryAndGlobalGate() {
        var gate=new CooldownGate();
        assertTrue(gate.acquire(Ability.LIGHTNING_STRIKE,100,6,40,20));
        assertFalse(gate.acquire(Ability.CRYO_BLAST,105,6,40,20));
        assertEquals(54,gate.remaining(Ability.LIGHTNING_STRIKE,106));
        assertFalse(gate.acquire(Ability.LIGHTNING_STRIKE,159,6,40,20));
        assertTrue(gate.acquire(Ability.LIGHTNING_STRIKE,160,6,40,20));
    }
    @Test void malformedConfigDoesNotSilentlyEnableDestruction() {
        assertThrows(IllegalArgumentException.class,()->NexusConfig.parse("[general]\nbreak_blocks = 'true'"));
        assertThrows(IllegalArgumentException.class,()->NexusConfig.parse("[general]\ndamage_scale = nan"));
        assertThrows(IllegalArgumentException.class,()->NexusConfig.parse("[performance]\nmax_effects = 100000000"));
        assertThrows(IllegalArgumentException.class,()->NexusConfig.parse("[status]\nburn_interval_ticks = 1.5"));
        assertThrows(IllegalArgumentException.class,()->NexusConfig.parse("[general]\nauto_activate_uuids=['BatteryRock_YT']"));
    }
    @Test void missingOptionalKeysUseSaneDefaultsAndIndividualOverridesWork() {
        var config=NexusConfig.parse("[abilities.cryo_blast]\ndamage=90\nenabled=false\n");
        assertEquals(20,config.powers.size());assertFalse(config.blockDamage);
        assertEquals(90,config.power(Ability.CRYO_BLAST).damage());assertFalse(config.power(Ability.CRYO_BLAST).enabled());
        assertTrue(config.power(Ability.LIGHTNING_STRIKE).enabled());
    }
}
