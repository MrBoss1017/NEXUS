package com.mrboss.nexus;

import net.minecraft.core.particles.DustParticleOptions;
import net.minecraft.core.particles.ParticleOptions;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.phys.Vec3;

/** Server-side geometry renders through vanilla particle packets; bounded every server tick. */
public final class NexusFx {
    private final NexusRuntime runtime;
    private int remaining;
    NexusFx(NexusRuntime runtime) { this.runtime = runtime; }
    public void reset() { remaining = runtime.config().maxParticles; }
    public void particle(ServerLevel level, ParticleOptions kind, Vec3 p, int count, double spread) {
        int actual = Math.min(remaining, count);
        if (actual <= 0) return;
        remaining -= actual;
        level.sendParticles(kind, p.x, p.y, p.z, actual, spread, spread, spread, .025);
    }
    public void point(ServerLevel level, Vec3 p, int color) {
        particle(level, new DustParticleOptions(color, 1.3f), p, 1, 0);
    }
    public void ring(ServerLevel level, Vec3 center, double radius, int color) {
        int count = Math.min(32, Math.max(8, (int)(radius * 5)));
        for (int i = 0; i < count; i++) {
            double angle = i * Math.PI * 2 / count;
            point(level, center.add(Math.cos(angle) * radius, .12, Math.sin(angle) * radius), color);
        }
    }
    public void line(ServerLevel level, Vec3 from, Vec3 to, int color) {
        int count = Math.min(36, Math.max(2, (int)(from.distanceTo(to) * 3)));
        for (int i = 0; i <= count; i++) point(level, from.lerp(to, (double)i/count), color);
    }
    public void bolt(ServerLevel level, Vec3 target, int color) {
        Vec3 last = target.add(0, 16, 0);
        for (int i = 1; i <= 6; i++) {
            Vec3 next = i == 6 ? target : target.add(runtime.random.nextDouble() * 3 - 1.5, 16 * (1 - i/6.0), runtime.random.nextDouble() * 3 - 1.5);
            line(level, last, next, color); last = next;
        }
        particle(level, ParticleTypes.ELECTRIC_SPARK, target.add(0, .5, 0), 14, .7);
        sound(level, target, SoundEvents.LIGHTNING_BOLT_IMPACT, .8f);
    }
    public void burst(ServerLevel level, Vec3 center, double radius, int color) {
        ring(level, center, radius, color);
        particle(level, ParticleTypes.EXPLOSION, center, 3, .8);
        sound(level, center, SoundEvents.GENERIC_EXPLODE.value(), .8f);
    }
    public void helix(ServerLevel level, Vec3 center, double radius, double height, double angle, int color) {
        for (int i = 0; i < 20; i++) {
            double t = i / 20.0, a = angle + t * Math.PI * 6;
            point(level, center.add(Math.cos(a) * radius * (.3 + t), t * height, Math.sin(a) * radius * (.3 + t)), color);
        }
    }
    public void sound(ServerLevel level, Vec3 center, SoundEvent event, float pitch) {
        if (runtime.config().volume > 0)
            level.playSound(null, center.x, center.y, center.z, event, SoundSource.HOSTILE, runtime.config().volume, pitch);
    }
}
