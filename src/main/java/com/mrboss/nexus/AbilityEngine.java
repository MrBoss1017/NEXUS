package com.mrboss.nexus;

import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.phys.*;
import java.util.*;
import static com.mrboss.nexus.NexusStatus.Kind.*;

/** Distinct attack geometries; shared collision, damage and cancellation rules. */
public final class AbilityEngine {
    private AbilityEngine() {}
    public static void start(NexusRuntime r, NexusSession s, Ability a, NexusConfig.Power p, int duration) {
        Vec3 center = r.aim(s);
        r.taunt(s, a.title.toUpperCase(Locale.ROOT) + "!");
        r.schedule(s, 0, p.windup(), age -> {
            if (age % 5 == 0) r.fx.ring(s.level, center, p.radius() * r.config().rangeScale, a.color);
            return true;
        });
        r.later(s, p.windup(), () -> pattern(r, s, a, p, center, Math.max(20,duration-p.windup()), 1));
    }
    public static void pattern(NexusRuntime r, NexusSession s, Ability a, NexusConfig.Power p, Vec3 center, int duration, double strength) {
        int pulses = p.pulses(), interval = Math.max(6, duration / Math.max(1,pulses));
        double radius = p.radius() * r.config().rangeScale, damage = p.damage() * strength;
        switch (a) {
            case LIGHTNING_STRIKE -> {
                for (int i=0;i<pulses;i++) {
                    Vec3 point = i % 3 == 0 ? center : scatter(r,s,center,Math.max(4,radius*2));
                    r.later(s,i*interval,()-> warn(r,s,point,a.color,12,()->{
                        r.fx.bolt(s.level,point,a.color);
                        r.aoe(s,point,p.radius(),damage,p.knockback(),STUN);
                        groundField(r,s,point,p.radius()*.65,p.lingeringDamage()*strength,40,a.color,NONE);
                    }));
                }
            }
            case METEOR_SHOWER -> {
                for(int i=0;i<pulses;i++) {
                    Vec3 point=i==0?center:scatter(r,s,center,Math.max(4,radius*2));
                    r.later(s,i*interval,()->meteor(r,s,point,p,strength,a.color));
                }
            }
            case DIMENSIONAL_RIFTS -> {
                int nodes=Math.min(8,pulses);
                for(int i=0;i<nodes;i++) {
                    Vec3 portal=ringPoint(center,Math.max(4,radius*2),i,nodes).add(0,2,0);
                    r.schedule(s,0,duration,age->{
                        if(age%5==0) r.fx.helix(s.level,portal,1.2,3,age*.2,a.color);
                        if(age%interval==0) {
                            LivingEntity target=r.nearest(s,portal,24);
                            projectile(r,s,portal,target==null?center:target.getEyePosition(),.65, p.radius(),damage,p.knockback(),a.color,SLOW,null);
                        }
                        return true;
                    });
                    r.later(s,duration-1,()->burst(r,s,portal,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,SLOW));
                }
            }
            case ARCANE_DEVASTATION -> {
                for(int i=0;i<pulses;i++) {
                    Vec3 point=i==0?center:scatter(r,s,center,Math.max(5,radius*2));
                    r.later(s,i*interval,()->warn(r,s,point,a.color,24,()->{
                        r.fx.line(s.level,point,point.add(0,22,0),a.color);
                        burst(r,s,point,p.radius(),damage,p.knockback(),a.color,VULNERABLE);
                        groundField(r,s,point,p.radius()*.8,p.lingeringDamage()*strength,60,a.color,NONE);
                    }));
                }
            }
            case INFERNO_TORNADO, TYPHOON_CYCLONE -> {
                boolean fire=a==Ability.INFERNO_TORNADO;
                int count=fire?1:Math.min(6,pulses);
                for(int i=0;i<count;i++) {
                    final int index=i;
                    r.schedule(s,0,duration,age->{
                        double angle=age*.045+index*Math.PI*2/count;
                        Vec3 base=r.ground(s,center.add(Math.cos(angle)*(fire?2:5),0,Math.sin(angle)*(fire?2:5)));
                        if(age%3==0) r.fx.helix(s.level,base,Math.max(1,radius),8,angle*5,a.color);
                        if(age%5==0) r.pull(s,base.add(0,2,0),radius+1,.12,.10);
                        if(age%10==0) r.aoe(s,base,p.radius(),damage,0,fire?BURN:LEVITATE);
                        if(!fire&&age%40==0) {r.fx.bolt(s.level,base,a.color);r.aoe(s,base,p.radius()*.5,damage*2,p.knockback(),STUN);}
                        if(age>=duration-2) burst(r,s,base,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,fire?BURN:NONE);
                        return true;
                    });
                }
            }
            case COSMIC_ANNIHILATION -> {
                Vec3 core=center.add(0,9,0);
                r.schedule(s,0,Math.max(10,duration/2),age->{
                    if(age%4==0){r.fx.helix(s.level,core,2+age*.015,4,age*.15,a.color);r.fx.line(s.level,center,core,a.color);}
                    return true;
                });
                for(int i=0;i<pulses;i++) {
                    Vec3 point=scatter(r,s,center,Math.max(7,radius*2));
                    r.later(s,duration/2+i*Math.max(2,interval/2),()->{
                        r.fx.line(s.level,core,point,a.color);
                        burst(r,s,point,p.radius(),damage,p.knockback(),a.color,VULNERABLE);
                    });
                }
            }
            case QUANTUM_SLICE -> {
                Vec3 origin=s.actor.position().add(0,1,0);
                double yaw=Math.atan2(center.z-origin.z,center.x-origin.x);
                for(int i=0;i<pulses;i++) {
                    final double angle=yaw+i*Math.PI*.45;
                    r.later(s,i*interval,()->{
                        Vec3 end=origin.add(Math.cos(angle)*Math.max(8,radius*2),0,Math.sin(angle)*Math.max(8,radius*2));
                        beam(r,s,origin,end,Math.max(.65,radius*.15),damage,p.knockback(),a.color,NONE);
                    });
                }
                r.later(s,duration-1,()->burst(r,s,origin,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,NONE));
            }
            case STELLAR_CONVERGENCE, VOID_STORM, PLASMA_CASCADE -> {
                int nodes=a==Ability.VOID_STORM?5:6;
                List<Vec3> points=new ArrayList<>();
                for(int i=0;i<nodes;i++) points.add(ringPoint(center,Math.max(5,radius*2),i,nodes).add(0,3,0));
                r.schedule(s,0,duration,age->{
                    if(age%5==0) for(int i=0;i<nodes;i++) {
                        Vec3 node=points.get(i);
                        r.fx.helix(s.level,node,.7,1.5,age*.15,a.color);
                        if(a!=Ability.VOID_STORM) r.fx.line(s.level,node,points.get((i+1)%nodes),a.color);
                    }
                    if(age%interval==0) for(Vec3 node:points) {
                        LivingEntity target=r.nearest(s,node,24);
                        projectile(r,s,node,target==null?center:target.getEyePosition(),a==Ability.VOID_STORM?.4:.7,
                            p.radius(),damage,p.knockback(),a.color,a==Ability.VOID_STORM?BLIND:a==Ability.PLASMA_CASCADE?STUN:BURN,null);
                    }
                    return true;
                });
                r.later(s,duration-1,()->{for(Vec3 node:points) burst(r,s,node.add(0,-2,0),p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,NONE);});
            }
            case PLASMA_NOVA, ANTIMATTER_ANNIHILATION -> {
                boolean anti=a==Ability.ANTIMATTER_ANNIHILATION;
                r.schedule(s,0,duration/2,age->{
                    if(age%4==0){r.fx.helix(s.level,center,1+age*.03,5,age*.2,a.color);r.pull(s,center.add(0,1,0),radius,.10,.025);}
                    if(age%20==0) r.aoe(s,center,p.radius()*.4,p.lingeringDamage()*strength,0,anti?VULNERABLE:STUN);
                    return true;
                });
                for(int i=0;i<pulses;i++) {
                    final int wave=i;
                    r.later(s,duration/2+i*Math.max(2,interval/2),()->wave(r,s,center,radius*(.5+wave*.14),damage,p.knockback(),a.color,anti?VULNERABLE:NONE));
                }
                r.later(s,duration-1,()->burst(r,s,center,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,NONE));
            }
            case CRYO_BLAST -> {
                Vec3 eye=s.actor.getEyePosition();
                Vec3 direction=center.subtract(eye).normalize();
                for(int i=0;i<pulses;i++) {
                    final int shot=i;
                    r.later(s,i*interval,()->{
                        double angle=(shot%3-1)*.16;
                        Vec3 dir=new Vec3(direction.x*Math.cos(angle)-direction.z*Math.sin(angle),direction.y,direction.x*Math.sin(angle)+direction.z*Math.cos(angle));
                        Vec3 end=eye.add(dir.scale(28));
                        beam(r,s,eye,end,Math.max(.6,radius*.3),damage,p.knockback(),a.color,FREEZE);
                    });
                }
                r.later(s,duration-1,()->{for(int i=0;i<8;i++) projectile(r,s,center.add(0,1,0),ringPoint(center,12,i,8),.7,p.radius(),p.finisherDamage()*strength,p.knockback(),a.color,FREEZE,null);});
            }
            case GRAVITY_COLLAPSE -> {
                r.schedule(s,0,duration-25,age->{
                    if(age%3==0)r.fx.helix(s.level,center,3,5,-age*.2,a.color);
                    if(age%4==0)r.pull(s,center.add(0,1.8,0),Math.max(8,radius*2),.22,.015);
                    if(age%10==0)r.aoe(s,center,p.radius(),damage,0,NONE);
                    return true;
                });
                r.later(s,duration-20,()->burst(r,s,center,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,LEVITATE));
            }
            case REALITY_SHATTER -> {
                for(int i=0;i<Math.min(15,pulses);i++) {
                    Vec3 point=i==0?center:scatter(r,s,center,Math.max(5,radius*2));
                    groundField(r,s,point,p.radius(),damage,duration,a.color,VULNERABLE);
                    r.schedule(s,0,duration,age->{if(age%10==0)r.fx.line(s.level,point,point.add(0,5,0),a.color);return true;});
                    r.later(s,duration-1,()->burst(r,s,point,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,NONE));
                }
            }
            case SOLAR_FLARE_BURST -> {
                Vec3 core=center.add(0,5,0);
                r.schedule(s,0,duration,age->{if(age%5==0)r.fx.helix(s.level,core,2.5,3,age*.12,a.color);return true;});
                for(int i=0;i<pulses;i++) {
                    final int ray=i;
                    r.later(s,i*interval,()->{
                        Vec3 end=ringPoint(center,18,ray,pulses);
                        beam(r,s,core,end,Math.max(.8,radius),damage,p.knockback(),a.color,BURN);
                    });
                }
                r.later(s,duration-1,()->burst(r,s,center,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,BURN));
            }
            case TEMPORAL_DISTORTION -> {
                for(int i=0;i<Math.min(12,pulses);i++) {
                    Vec3 point=i==0?center:scatter(r,s,center,6);
                    groundField(r,s,point,p.radius(),damage,duration,a.color,SLOW);
                    r.schedule(s,0,duration,age->{
                        if(age%20==0) for(LivingEntity target:r.targets(s,point,radius)) target.setDeltaMovement(target.getDeltaMovement().scale(.25));
                        return true;
                    });
                    r.later(s,duration-1,()->burst(r,s,point,p.finisherRadius(),p.finisherDamage()*strength,p.knockback(),a.color,STUN));
                }
            }
            case VOLCANIC_ERUPTION -> {
                for(int i=0;i<pulses;i++) {
                    Vec3 vent=i==0?center:scatter(r,s,center,8);
                    r.later(s,i*interval,()->warn(r,s,vent,a.color,16,()->{
                        burst(r,s,vent,p.radius(),damage,p.knockback(),a.color,BURN);
                        r.fx.helix(s.level,vent,1,8,r.now()*.1,a.color);
                        for(int j=0;j<3;j++) projectile(r,s,vent.add(0,5,0),scatter(r,s,vent,5),.6,p.radius()*.7,damage*.65,p.knockback(),a.color,BURN,null);
                        groundField(r,s,vent,p.radius()*.8,p.lingeringDamage()*strength,100,a.color,BURN);
                    }));
                }
            }
            case NEXUS_FINALE -> throw new IllegalArgumentException("Use FinaleTimeline");
        }
    }
    public static Vec3 ringPoint(Vec3 center,double radius,int index,int count) {
        double angle=index*Math.PI*2/count;
        return center.add(Math.cos(angle)*radius,0,Math.sin(angle)*radius);
    }
    public static Vec3 scatter(NexusRuntime r,NexusSession s,Vec3 center,double radius) {
        double angle=r.random.nextDouble()*Math.PI*2, distance=Math.sqrt(r.random.nextDouble())*radius;
        return r.ground(s,center.add(Math.cos(angle)*distance,0,Math.sin(angle)*distance));
    }
    public static void warn(NexusRuntime r,NexusSession s,Vec3 point,int color,int ticks,Runnable impact) {
        r.schedule(s,0,ticks,age->{if(age%4==0)r.fx.ring(s.level,point,1.5,color);return true;});
        r.later(s,ticks,impact);
    }
    public static void burst(NexusRuntime r,NexusSession s,Vec3 point,double radius,double damage,double fling,int color,NexusStatus.Kind status) {
        r.fx.burst(s.level,point,Math.min(16,radius*r.config().rangeScale),color);
        r.aoe(s,point,radius,damage,fling,status);
    }
    public static void meteor(NexusRuntime r,NexusSession s,Vec3 point,NexusConfig.Power p,double strength,int color) {
        warn(r,s,point,color,16,()->projectile(r,s,point.add(r.random.nextDouble()*4-2,22,0),point,1.1,p.radius(),p.damage()*strength,p.knockback(),color,BURN,
            ()->groundField(r,s,point,p.radius()*.5,p.lingeringDamage()*strength,160,color,BURN)));
    }
    public static void groundField(NexusRuntime r,NexusSession s,Vec3 point,double radius,double damage,int ticks,int color,NexusStatus.Kind status) {
        r.schedule(s,0,ticks,age->{
            if(age%10==0){r.fx.ring(s.level,point,radius*r.config().rangeScale,color);r.aoe(s,point,radius,damage,0,status);}
            return true;
        });
    }
    public static void beam(NexusRuntime r,NexusSession s,Vec3 from,Vec3 requested,double width,double damage,double knockback,int color,NexusStatus.Kind status) {
        HitResult hit=s.level.clip(new ClipContext(from,requested,ClipContext.Block.COLLIDER,ClipContext.Fluid.NONE,s.actor));
        Vec3 end=hit.getType()==HitResult.Type.MISS?requested:hit.getLocation();
        r.fx.line(s.level,from,end,color);
        Vec3 direction=end.subtract(from); double length2=direction.lengthSqr();
        if(length2<.0001)return;
        int count=0;
        for(LivingEntity target:s.level.getEntitiesOfClass(LivingEntity.class,new AABB(from,end).inflate(width),e->r.enemy(s,e))) {
            if(count++>=r.config().maxTargets)break;
            Vec3 mid=target.position().add(0,target.getBbHeight()/2,0);
            double t=Math.clamp(mid.subtract(from).dot(direction)/length2,0,1);
            if(mid.distanceToSqr(from.add(direction.scale(t)))<=width*width+target.getBbWidth()*target.getBbWidth()) {
                r.damage(s,target,damage,false);NexusStatus.apply(r,s,target,status);
                target.push(direction.normalize().scale(Math.min(1,knockback*r.config().knockbackScale)));target.syncVelocity=true;
            }
        }
    }
    public static void projectile(NexusRuntime r,NexusSession s,Vec3 origin,Vec3 goal,double speed,double radius,double damage,double fling,int color,NexusStatus.Kind status,Runnable after) {
        final Vec3[] position={origin}; Vec3 velocity=goal.subtract(origin).normalize().scale(speed);
        int life=Math.min(160,Math.max(5,(int)(origin.distanceTo(goal)/speed)+3));
        r.schedule(s,0,life,age->{
            Vec3 from=position[0],to=from.add(velocity);
            if(!s.level.hasChunkAt(BlockPos.containing(to)))return false;
            var hit=s.level.clip(new ClipContext(from,to,ClipContext.Block.COLLIDER,ClipContext.Fluid.NONE,s.actor));
            Vec3 impact=hit.getType()==HitResult.Type.MISS?null:hit.getLocation();
            double closest=impact==null?Double.POSITIVE_INFINITY:from.distanceToSqr(impact);
            // Swept collision avoids tunnelling at fast meteor/projectile speeds.
            for(LivingEntity target:s.level.getEntitiesOfClass(LivingEntity.class,new AABB(from,to).inflate(.5),e->r.enemy(s,e))) {
                Optional<Vec3> entry=target.getBoundingBox().inflate(.25).clip(from,to);
                if(entry.isPresent()&&entry.get().distanceToSqr(from)<closest){impact=entry.get();closest=from.distanceToSqr(impact);}
            }
            r.fx.line(s.level,from,to,color); r.fx.particle(s.level,ParticleTypes.END_ROD,to,2,.1);
            if(impact!=null||age>=life-2||to.distanceToSqr(goal)<speed*speed) {
                burst(r,s,impact==null?to:impact,radius,damage,fling,color,status);
                if(after!=null)after.run();return false;
            }
            position[0]=to;return true;
        });
    }
    public static void wave(NexusRuntime r,NexusSession s,Vec3 center,double endRadius,double damage,double fling,int color,NexusStatus.Kind status) {
        Set<UUID> hit=new HashSet<>();
        r.schedule(s,0,20,age->{
            double radius=Math.max(.2,endRadius*(age+1)/20);
            if(age%2==0)r.fx.ring(s.level,center,radius,color);
            for(LivingEntity target:r.targets(s,center,radius+1)) {
                double distance=target.position().distanceTo(center);
                if(Math.abs(distance-radius)<=1.5&&hit.add(target.getUUID())) {
                    r.damage(s,target,damage,false);NexusStatus.apply(r,s,target,status);
                    target.push(target.position().subtract(center).normalize().scale(Math.min(1.5,fling*r.config().knockbackScale)));target.syncVelocity=true;
                }
            }
            return true;
        });
    }
}
