package com.mrboss.nexus.mixin;

import com.mrboss.nexus.NexusMod;
import com.mrboss.nexus.NexusStatus;
import net.minecraft.world.entity.LivingEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.ModifyVariable;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(LivingEntity.class)
public abstract class LivingEntityMixin {
    @Inject(method = "heal", at = @At("HEAD"), cancellable = true)
    private void nexus$preventHealing(float amount, CallbackInfo ci) {
        var r = NexusMod.runtime();
        if (r != null && r.blockHealing((LivingEntity)(Object)this)) ci.cancel();
    }
    @Inject(method = "jumpFromGround", at = @At("HEAD"), cancellable = true)
    private void nexus$rootedJump(CallbackInfo ci) {
        if (NexusStatus.immobilized((LivingEntity)(Object)this)) ci.cancel();
    }
    @ModifyVariable(method = "hurtServer", at = @At("HEAD"), argsOnly = true, ordinal = 0)
    private float nexus$vulnerability(float amount) {
        var r = NexusMod.runtime();
        if (r != null && ((LivingEntity)(Object)this).hasEffect(NexusStatus.VULNERABLE))
            return (float)(amount * r.config().weaknessMultiplier);
        return amount;
    }
}
