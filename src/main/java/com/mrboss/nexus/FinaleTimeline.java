package com.mrboss.nexus;

import net.minecraft.world.phys.Vec3;
import java.util.List;
import static com.mrboss.nexus.Ability.*;

/** Preserves all 34 named source phases. Configurable phase duration bounds the encounter. */
public final class FinaleTimeline {
    public record Phase(String title, Ability primary, Ability secondary, NexusMinions.Type npc) {}
    public static final List<Phase> PHASES = List.of(
        new Phase("The Awakening of Chaos",null,null,null),
        new Phase("Elemental Chaos",LIGHTNING_STRIKE,CRYO_BLAST,null),
        new Phase("Meteor Apocalypse",METEOR_SHOWER,null,null),
        new Phase("Dimensional Rift Chaos",DIMENSIONAL_RIFTS,null,null),
        new Phase("Plasma Nova",PLASMA_NOVA,null,null),
        new Phase("Quantum Collapse",QUANTUM_SLICE,null,null),
        new Phase("Inferno Apocalypse",INFERNO_TORNADO,null,null),
        new Phase("The Convergence",STELLAR_CONVERGENCE,null,null),
        new Phase("Ultimate Cataclysm",COSMIC_ANNIHILATION,LIGHTNING_STRIKE,null),
        new Phase("Singularity Vortex",GRAVITY_COLLAPSE,null,NexusMinions.Type.DARK_HERALD),
        new Phase("Reality Fracture",REALITY_SHATTER,DIMENSIONAL_RIFTS,NexusMinions.Type.VOID_SENTINEL),
        new Phase("Elemental Convergence",VOLCANIC_ERUPTION,CRYO_BLAST,NexusMinions.Type.ELEMENTAL_TITAN),
        new Phase("Shadow Apocalypse",VOID_STORM,null,NexusMinions.Type.SHADOW_WRAITH),
        new Phase("Cosmic Storm",METEOR_SHOWER,SOLAR_FLARE_BURST,NexusMinions.Type.COSMIC_DESTROYER),
        new Phase("Nexus Ascension",COSMIC_ANNIHILATION,PLASMA_CASCADE,NexusMinions.Type.COSMIC_DESTROYER),
        new Phase("Apocalyptic Lightning Storm",LIGHTNING_STRIKE,null,null),
        new Phase("Endless Meteor Apocalypse",METEOR_SHOWER,null,null),
        new Phase("Dimensional Chaos",DIMENSIONAL_RIFTS,null,null),
        new Phase("Arcane Annihilation",ARCANE_DEVASTATION,null,null),
        new Phase("Inferno Finale",INFERNO_TORNADO,null,null),
        new Phase("Cosmic Annihilation Finale",COSMIC_ANNIHILATION,null,null),
        new Phase("Quantum Slice Finale",QUANTUM_SLICE,null,null),
        new Phase("Plasma Vortex Convergence",PLASMA_NOVA,PLASMA_CASCADE,null),
        new Phase("Glacial Storm",CRYO_BLAST,null,null),
        new Phase("Gravitational Singularity",GRAVITY_COLLAPSE,null,null),
        new Phase("Reality Fractures",REALITY_SHATTER,null,null),
        new Phase("Solar Core Ignition",SOLAR_FLARE_BURST,null,null),
        new Phase("Magma Chambers",VOLCANIC_ERUPTION,null,null),
        new Phase("Antimatter Cascade",ANTIMATTER_ANNIHILATION,null,null),
        new Phase("Gravity Nexus",GRAVITY_COLLAPSE,TEMPORAL_DISTORTION,null),
        new Phase("Void Singularity",VOID_STORM,DIMENSIONAL_RIFTS,null),
        new Phase("The Four Elements",VOLCANIC_ERUPTION,CRYO_BLAST,NexusMinions.Type.ELEMENTAL_TITAN),
        new Phase("Everything at Once",PLASMA_NOVA,LIGHTNING_STRIKE,NexusMinions.Type.DARK_HERALD),
        new Phase("Beyond Ultimate",ANTIMATTER_ANNIHILATION,REALITY_SHATTER,NexusMinions.Type.COSMIC_DESTROYER)
    );
    private FinaleTimeline() {}
    public static void start(NexusRuntime r,NexusSession s) {
        int ticks=r.config().finalePhaseTicks;
        boolean previousRecruitment=s.recruitment;
        s.finalePreviousRecruitment=previousRecruitment;
        s.recruitment=true;s.bar.setDarkenScreen(true);
        r.schedule(s,0,ticks*PHASES.size(),age->{
            int index=Math.min(PHASES.size()-1,age/ticks), local=age%ticks;
            if(s.phase!=index+1){
                s.phase=index+1;Phase phase=PHASES.get(index);
                r.taunt(s,"Phase "+s.phase+"/34 · "+phase.title);
                Vec3 center=r.aim(s);
                double power=1+index*.035;
                if(phase.primary!=null)launch(r,s,phase.primary,center,ticks,power);
                if(phase.secondary!=null)r.later(s,ticks/3,()->launch(r,s,phase.secondary,center,Math.max(20,ticks*2/3),power*.8));
                if(phase.npc!=null) {
                    int count=index>=32?5:2;
                    for(int n=0;n<count;n++)r.minions.spawn(s,phase.npc,AbilityEngine.scatter(r,s,s.actor.position(),7));
                    if(index>=32)for(NexusMinions.Type type:NexusMinions.Type.values())r.minions.spawn(s,type,AbilityEngine.scatter(r,s,s.actor.position(),9));
                }
            }
            if(index==0&&local%4==0)r.fx.helix(s.level,s.actor.position(),2+local*.015,10,local*.1,0xDD55FF);
            if(index==12&&local%20==0){
                for(var target:r.targets(s,s.actor.position(),18))r.damage(s,target,15,false);
            }
            if(index==31&&local%60==0){
                Vec3 point=AbilityEngine.scatter(r,s,r.aim(s),5);r.fx.bolt(s.level,point,LIGHTNING_STRIKE.color);
                r.aoe(s,point,35,280,100,NexusStatus.Kind.STUN);
            }
            if(index>=32&&local%80==0){
                Ability extra=Ability.values()[(local/80+index)%19];launch(r,s,extra,r.aim(s),60,1.2);
            }
            if(index==33&&local==ticks-20){
                r.taunt(s,"TOTAL... COSMIC... OBLITERATION!");
                var finalPower=r.config().power(NEXUS_FINALE);
                AbilityEngine.burst(r,s,s.actor.position(),finalPower.finisherRadius(),finalPower.finisherDamage(),finalPower.knockback(),0xFFCCFF,NexusStatus.Kind.VULNERABLE);
            }
            if(age>=ticks*PHASES.size()-2){
                r.minions.clearNpcs(s);s.recruitment=previousRecruitment;
                if(!previousRecruitment)r.minions.clear(s);
                r.taunt(s,"The Nexus rests... for now.");s.bar.setDarkenScreen(false);
            }
            return true;
        });
    }
    private static void launch(NexusRuntime r,NexusSession s,Ability a,Vec3 center,int duration,double power){
        NexusConfig.Power p=r.config().power(a);
        if(!p.enabled())return;
        // Finale uses the same mechanics at an increased magnitude with bounded emissions.
        var reduced=new NexusConfig.Power(true,p.damage(),p.radius(),p.knockback(),duration,p.cooldown(),p.windup(),
            Math.min(6,p.pulses()),p.finisherDamage(),p.finisherRadius(),p.lingeringDamage());
        AbilityEngine.pattern(r,s,a,reduced,center,duration,power);
    }
}
