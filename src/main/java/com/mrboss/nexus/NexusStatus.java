package com.mrboss.nexus;

import net.minecraft.core.Holder;
import net.minecraft.core.Registry;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.effect.MobEffect;
import net.minecraft.world.effect.MobEffectCategory;
import net.minecraft.world.effect.MobEffectInstance;
import net.minecraft.world.effect.MobEffects;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.ai.attributes.AttributeModifier;
import net.minecraft.world.entity.ai.attributes.Attributes;

public final class NexusStatus {
    public enum Kind { NONE, STUN, BURN, FREEZE, SLOW, VULNERABLE, BLIND, LEVITATE }
    private static final class Effect extends MobEffect {
        Effect(int color) { super(MobEffectCategory.HARMFUL, color); }
    }
    public static final Holder<MobEffect> STUN = register("stun", new Effect(0xFFFF55)
        .addAttributeModifier(Attributes.MOVEMENT_SPEED, NexusMod.id("stun_speed"), -1, AttributeModifier.Operation.ADD_MULTIPLIED_TOTAL));
    public static final Holder<MobEffect> FREEZE = register("freeze", new Effect(0x99DDFF)
        .addAttributeModifier(Attributes.MOVEMENT_SPEED, NexusMod.id("freeze_speed"), -1, AttributeModifier.Operation.ADD_MULTIPLIED_TOTAL));
    public static final Holder<MobEffect> VULNERABLE = register("vulnerable", new Effect(0xCC0066));
    private static Holder<MobEffect> register(String id, MobEffect effect) {
        return Registry.registerForHolder(BuiltInRegistries.MOB_EFFECT, NexusMod.id(id), effect);
    }
    public static void initialize() {}
    public static boolean immobilized(LivingEntity entity) { return entity.hasEffect(STUN) || entity.hasEffect(FREEZE); }
    public static void apply(NexusRuntime r, NexusSession owner, LivingEntity target, Kind kind) {
        NexusConfig c = r.config();
        switch (kind) {
            case STUN -> target.addEffect(new MobEffectInstance(STUN, c.stunTicks), owner.actor);
            case FREEZE -> target.addEffect(new MobEffectInstance(FREEZE, c.freezeTicks), owner.actor);
            case SLOW -> target.addEffect(new MobEffectInstance(MobEffects.SLOWNESS, c.slowTicks, 3), owner.actor);
            case VULNERABLE -> target.addEffect(new MobEffectInstance(VULNERABLE, c.weaknessTicks), owner.actor);
            case BLIND -> target.addEffect(new MobEffectInstance(MobEffects.BLINDNESS, c.blindTicks), owner.actor);
            case LEVITATE -> target.addEffect(new MobEffectInstance(MobEffects.LEVITATION, c.levitateTicks), owner.actor);
            case BURN -> r.burn(owner, target);
            default -> { }
        }
    }
}
