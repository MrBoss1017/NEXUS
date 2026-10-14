package com.mrboss.nexus;

import net.minecraft.core.BlockPos;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.*;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.entity.monster.Monster;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.phys.Vec3;
import java.util.*;

public final class NexusMinions {
    public enum Type {
        DARK_HERALD("Dark Herald",800,35,40,0x660099),
        VOID_SENTINEL("Void Sentinel",1000,45,50,0x220055),
        ELEMENTAL_TITAN("Elemental Titan",1500,60,60,0xFF6600),
        SHADOW_WRAITH("Shadow Wraith",600,30,30,0x333344),
        COSMIC_DESTROYER("Cosmic Destroyer",1200,50,40,0x9955DD);
        public final String title; public final int hp,damage,cooldown,color;
        Type(String title,int hp,int damage,int cooldown,int color){this.title=title;this.hp=hp;this.damage=damage;this.cooldown=cooldown;this.color=color;}
    }
    public static final class Member {
        final NexusSession owner; final LivingEntity entity; final boolean originalNoAi; final Type npc;
        UUID parent; boolean infected; int clone; long nextAttack,expires;
        Member(NexusSession owner,LivingEntity entity,UUID parent,Type npc,long expires){
            this.owner=owner;this.entity=entity;this.parent=parent;this.npc=npc;this.expires=expires;
            originalNoAi=entity instanceof Mob mob && mob.isNoAi();
            if(entity instanceof Mob mob){
                mob.setTarget(null);mob.setNoAi(true);
                if(npc==null){mob.addTag("nexus_recruited_ai");if(originalNoAi)mob.addTag("nexus_previous_no_ai");}
            }
        }
    }
    private final NexusRuntime r;
    private final Map<UUID,Member> members=new LinkedHashMap<>();
    private final Map<UUID,Long> immunity=new HashMap<>();
    NexusMinions(NexusRuntime r){this.r=r;}
    public int size(){return members.size();}
    public int count(NexusSession s){return (int)members.values().stream().filter(m->m.owner==s&&m.npc==null).count();}
    public boolean allied(NexusSession s,LivingEntity target){Member m=members.get(target.getUUID());return m!=null&&m.owner==s;}
    public boolean infected(LivingEntity entity){Member m=members.get(entity.getUUID());return m!=null&&m.infected;}
    public NexusSession owner(LivingEntity entity){Member m=members.get(entity.getUUID());return m==null?null:m.owner;}
    public boolean recruit(NexusSession owner,LivingEntity recruiter,LivingEntity target){
        if(!owner.recruitment||!owner.valid()||!r.enemy(owner,target)||members.containsKey(target.getUUID())||r.session(target)!=null
            ||count(owner)>=r.config().maxMinions||r.now()<immunity.getOrDefault(target.getUUID(),0L))return false;
        if(target instanceof ServerPlayer){if(!r.config().recruitPlayers)return false;}
        else if(!r.config().recruitMobs)return false;
        Member m=new Member(owner,target,recruiter.getUUID(),null,Long.MAX_VALUE);members.put(target.getUUID(),m);
        // Source recruitment heals the boss by the recruit's current health; it does not drain the recruit.
        owner.actor.setHealth(Math.min(owner.actor.getMaxHealth(),owner.actor.getHealth()+target.getHealth()));
        immunity.put(target.getUUID(),r.now()+r.config().recruitCooldown);
        if(owner.infection&&r.config().infectionEnabled)infect(m);
        r.fx.burst(owner.level,target.position(),1.5,0xAA33FF);
        NexusRuntime.tell(target,"Recruited by Nexus. /nexus free or Release Charm to leave.");
        return true;
    }
    private void infect(Member member){
        if(member.infected)return;
        member.infected=true;member.clone=r.random.nextInt(3);
        NexusRuntime.tell(member.entity,"Nexus clone power: "+cloneName(member.clone)+" · /nexus clone");
    }
    public void infection(NexusSession s,boolean enabled){
        s.infection=enabled&&r.config().infectionEnabled;
        for(Member m:members.values())if(m.owner==s&&m.npc==null){if(s.infection)infect(m);else m.infected=false;}
    }
    public void recruitment(NexusSession s,boolean enabled){s.recruitment=enabled;if(!enabled)clear(s);}
    public void release(UUID id,boolean manual){
        Member m=members.remove(id);if(m==null)return;
        if(m.entity instanceof Mob mob){mob.setNoAi(m.originalNoAi);mob.setTarget(null);mob.removeTag("nexus_recruited_ai");mob.removeTag("nexus_previous_no_ai");}
        for(Member child:members.values())if(child.parent.equals(id))child.parent=m.owner.actor.getUUID();
        if(m.npc!=null&&!m.entity.isRemoved())m.entity.discard();
        if(manual){immunity.put(id,r.now()+100);NexusRuntime.tell(m.entity,"Freed from the Nexus. Recruitment immunity: 5 seconds.");}
    }
    public void clear(NexusSession s){for(Member m:List.copyOf(members.values()))if(m.owner==s)release(m.entity.getUUID(),false);}
    public void clearNpcs(NexusSession s){for(Member m:List.copyOf(members.values()))if(m.owner==s&&m.npc!=null)release(m.entity.getUUID(),false);}
    public void tick(){
        immunity.entrySet().removeIf(e->e.getValue()<r.now());
        for(Member m:List.copyOf(members.values())) {
            if(!m.owner.valid()||!m.entity.isAlive()||m.entity.isRemoved()||m.entity.level()!=m.owner.level||r.now()>=m.expires){release(m.entity.getUUID(),false);continue;}
            if(r.now()%10==0){
                LivingEntity recruiter=m.owner.actor;
                Member parent=members.get(m.parent);if(parent!=null)recruiter=parent.entity;
                r.fx.line(m.owner.level,recruiter.position().add(0,1,0),m.entity.position().add(0,1,0),m.infected?0xFF4488:0x9933FF);
            }
            if(r.now()%5==0) {
                contact(m.owner,m.entity);
                if(m.entity instanceof Mob)moveAndAttack(m);
            }
            if(m.owner.phase>0&&r.now()%r.config().minionInterval==0&&m.npc==null)support(m);
        }
        if(r.now()%5==0)for(NexusSession s:r.sessions())if(s.recruitment)contact(s,s.actor);
    }
    private void contact(NexusSession s,LivingEntity recruiter){
        if(!s.recruitment)return;
        for(LivingEntity target:r.targets(s,recruiter.position(),r.config().contactRange))recruit(s,recruiter,target);
    }
    private void moveAndAttack(Member m){
        LivingEntity target=r.nearest(m.owner,m.entity.position(),32);
        Vec3 goal=target==null?m.owner.actor.position():target.position();
        double distance=m.entity.position().distanceTo(goal);
        if(distance>(target==null?4:5)) {
            Vec3 velocity=goal.subtract(m.entity.position()).multiply(1,0,1).normalize().scale(.18);
            m.entity.setDeltaMovement(velocity.x,m.entity.getDeltaMovement().y,velocity.z);
            if(m.entity.horizontalCollision&&m.entity.onGround())m.entity.setDeltaMovement(velocity.x,.42,velocity.z);
            m.entity.syncVelocity=true;
        }
        if(target!=null&&r.now()>=m.nextAttack) {
            m.entity.lookAt(net.minecraft.commands.arguments.EntityAnchorArgument.Anchor.EYES,target.getEyePosition());
            int cooldown=m.npc==null?40:m.npc.cooldown;
            m.nextAttack=r.now()+cooldown;
            double damage=m.npc==null?25:m.npc.damage*r.config().npcDamageScale;
            AbilityEngine.projectile(r,m.owner,m.entity.getEyePosition(),target.getEyePosition(),.6,12,damage,25,m.npc==null?0x9955FF:m.npc.color,NexusStatus.Kind.NONE,null);
        }
        if(m.npc!=null&&r.now()%20==0)for(Member ally:List.copyOf(members.values())) {
            if(ally.owner==m.owner&&ally.npc==null&&ally.entity.distanceToSqr(m.entity)<6.25) {
                ally.entity.setHealth(Math.min(ally.entity.getMaxHealth(),ally.entity.getHealth()+(float)r.config().minionHeal));
                r.fx.particle(m.owner.level,ParticleTypes.HEART,ally.entity.position().add(0,2,0),1,.1);
            }
        }
    }
    private void support(Member m){
        LivingEntity target=r.nearest(m.owner,m.entity.position(),10);
        if(target==null)return;
        r.damage(m.owner,target,15+r.random.nextInt(21),false);
        recruit(m.owner,m.entity,target);
        int phase=m.owner.phase;
        Ability a=phase<=5?Ability.LIGHTNING_STRIKE:phase<=10?Ability.CRYO_BLAST:phase<=15?Ability.DIMENSIONAL_RIFTS:phase<=25?Ability.METEOR_SHOWER:Ability.PLASMA_NOVA;
        if(phase<=5){r.fx.bolt(m.owner.level,target.position(),a.color);r.aoe(m.owner,target.position(),15,80,40,NexusStatus.Kind.STUN);}
        else if(phase<=15) {
            for(int i=0;i<3;i++)AbilityEngine.projectile(r,m.owner,m.entity.getEyePosition(),target.getEyePosition().add(i-1,0,0),.65,12,60,30,a.color,phase<=10?(i%2==0?NexusStatus.Kind.FREEZE:NexusStatus.Kind.BURN):NexusStatus.Kind.BLIND,null);
        }else if(phase<=25)AbilityEngine.meteor(r,m.owner,target.position(),r.config().power(a),.35,a.color);
        else AbilityEngine.burst(r,m.owner,m.entity.position(),25,120,60,a.color,NexusStatus.Kind.VULNERABLE);
    }
    public boolean cloneAttack(LivingEntity entity){
        Member m=members.get(entity.getUUID());
        if(m==null||!m.infected){NexusRuntime.tell(entity,"You are not an infected Nexus clone.");return false;}
        if(r.now()<m.nextAttack||NexusStatus.immobilized(entity)){NexusRuntime.tell(entity,"Clone power is cooling down.");return false;}
        m.nextAttack=r.now()+40;
        Vec3 from=entity.getEyePosition(),end=from.add(entity.getLookAngle().scale(12));
        if(m.clone==0)for(int i=0;i<5;i++) {
            Vec3 point=AbilityEngine.scatter(r,m.owner,entity.position(),4);
            r.fx.bolt(m.owner.level,point,0xFFFF99);r.aoe(m.owner,point,10,40,20,NexusStatus.Kind.STUN);
        }else for(int i=0;i<(m.clone==1?3:4);i++) {
            AbilityEngine.projectile(r,m.owner,from,end.add((i-1)*.7,0,0),.65,m.clone==1?8:6,m.clone==1?35:25,15,m.clone==1?0xFF6633:0x99DDFF,
                m.clone==1?NexusStatus.Kind.BURN:NexusStatus.Kind.FREEZE,null);
        }
        return true;
    }
    public static String cloneName(int n){return switch(n){case 0->"Lightning Strike";case 1->"Fire Blast";default->"Ice Shard";};}
    public boolean spawn(NexusSession owner,Type type,Vec3 position){
        if(members.values().stream().filter(m->m.npc!=null).count()>=r.config().maxNpcs)return false;
        Vec3 point=r.ground(owner,position);
        if(!owner.level.hasChunkAt(BlockPos.containing(point))||!owner.level.getWorldBorder().isWithinBounds(BlockPos.containing(point)))return false;
        // Vanilla entity types carry reliable client renderers; variants get custom names, stats, AI and auras.
        EntityType<? extends Mob> vanilla=switch(type){case VOID_SENTINEL->EntityTypes.WITHER_SKELETON;case ELEMENTAL_TITAN->EntityTypes.HUSK;case SHADOW_WRAITH->EntityTypes.STRAY;case COSMIC_DESTROYER->EntityTypes.PIGLIN_BRUTE;default->EntityTypes.ZOMBIE;};
        Mob npc=vanilla.create(owner.level,EntitySpawnReason.TRIGGERED);
        if(npc==null)return false;
        npc.setPos(point);npc.setCustomName(Component.literal(type.title));npc.setCustomNameVisible(true);npc.setPersistenceRequired();
        npc.getAttribute(Attributes.MAX_HEALTH).setBaseValue(type.hp*r.config().npcHealthScale);npc.setHealth(npc.getMaxHealth());
        npc.setItemSlot(EquipmentSlot.HEAD,new ItemStack(Items.CARVED_PUMPKIN));npc.setDropChance(EquipmentSlot.HEAD,0);
        npc.addTag("nexus_ephemeral");
        Member m=new Member(owner,npc,owner.actor.getUUID(),type,r.now()+r.config().npcLifetime);
        members.put(npc.getUUID(),m);
        if(!owner.level.addFreshEntity(npc)){members.remove(npc.getUUID());return false;}
        r.fx.burst(owner.level,point,2,type.color);return true;
    }
}
