package com.mrboss.nexus.verification;

import com.mrboss.nexus.*;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerTickEvents;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.*;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.phys.Vec3;
import java.nio.file.*;
import java.util.*;

/** Separate opt-in verification mod. Never included in the normal Nexus JAR. */
public final class NexusVerification implements ModInitializer {
    private final List<Mob> targets=new ArrayList<>();
    private final List<String> results=new ArrayList<>();
    private final Set<Integer> phases=new HashSet<>();
    private Mob boss;
    private long stageStart,damageStart;
    private int stage=-1;
    private boolean finished;
    private NexusSession session;
    private void require(boolean ok,String description){if(!ok)throw new AssertionError(description);results.add("PASS "+description);NexusMod.LOG.info("VERIFY PASS {}",description);}
    @Override public void onInitialize(){
        ServerLifecycleEvents.SERVER_STARTED.register(server->{
            try{
                NexusRuntime r=NexusMod.runtime();var level=server.overworld();
                net.minecraft.world.item.CreativeModeTabs.tryRebuildTabContents(level.enabledFeatures(),true,server.registryAccess());
                var tab=net.minecraft.core.registries.BuiltInRegistries.CREATIVE_MODE_TAB.getValue(NexusMod.id("nexus"));
                require(tab!=null&&tab.getDisplayItems().size()==25,"creative tab contains all 25 custom items");
                server.tickRateManager().setTickRate(200);
                for(int x=-2;x<=2;x++)for(int z=-2;z<=2;z++)level.setChunkForced(x,z,true);
                for(int x=-22;x<=22;x++)for(int z=-22;z<=22;z++)level.setBlockAndUpdate(new BlockPos(x,64,z),Blocks.STONE.defaultBlockState());
                boss=EntityTypes.WITHER_SKELETON.create(level,EntitySpawnReason.COMMAND);boss.setPos(0,65,0);boss.setNoAi(true);boss.setPersistenceRequired();level.addFreshEntity(boss);
                require(r.activate(boss,true),"boss activation");session=r.session(boss);
                require(boss.getMaxHealth()==600,"600 HP boss attribute");
                boss.setHealth(500);boss.heal(10);require(boss.getHealth()==500,"healing mixin blocks boss regeneration");boss.setHealth(600);
                for(int x=5;x<=17;x+=3)for(int z=-6;z<=6;z+=3){
                    Mob mob=EntityTypes.ZOMBIE.create(level,EntitySpawnReason.COMMAND);mob.setNoAi(true);mob.setItemSlot(EquipmentSlot.HEAD,new net.minecraft.world.item.ItemStack(net.minecraft.world.item.Items.CARVED_PUMPKIN));mob.setPos(x,65,z);mob.getAttribute(Attributes.MAX_HEALTH).setBaseValue(1000);mob.setHealth(1000);level.addFreshEntity(mob);targets.add(mob);
                }
                final boolean[] ran={false};r.later(session,0,()->ran[0]=true);r.later(session,3,()->require(ran[0],"zero-delay scheduler callback executes"));
                stageStart=r.now()+120;
            }catch(Throwable error){finish(NexusMod.runtime(),error);}
        });
        ServerTickEvents.END_SERVER_TICK.register(server->{
            var r=NexusMod.runtime();if(r==null||finished||boss==null)return;
            try{
                if(r.now()<stageStart)return;
                requireBudget(r);
                if(stage==-1){next(r);return;}
                if(stage<19){
                    if(r.now()-stageStart>=360){
                        require(r.failedEffects==0,"no effect exception: "+Ability.values()[stage].id());
                        require(r.damageEvents>damageStart,"damage landed: "+Ability.values()[stage].id());
                        next(r);
                    }
                }else if(stage==19){
                    if(session.phase>0)phases.add(session.phase);
                    if(r.now()-stageStart>r.config().finalePhaseTicks*34+50){
                        require(phases.size()==34,"all 34 finale phases executed");
                        require(r.failedEffects==0,"finale completed without effect exceptions");
                        r.cancel(session);stage++;stageStart=r.now()+20;
                    }
                }else if(stage==20){
                    Mob target=targets.getFirst();target.setPos(2,65,0);target.setHealth(1000);
                    session.recruitment=true;session.infection=true;
                    require(r.minions.recruit(session,boss,target),"minion recruitment");
                    require(r.minions.allied(session,target),"recruitment grants friendly-fire immunity");
                    require(r.minions.infected(target),"infection assigns clone role");
                    float health=target.getHealth();r.damage(session,target,500,false);require(target.getHealth()==health,"Nexus damage cannot hit its minions");
                    r.minions.release(target.getUUID(),true);require(r.minions.size()==0,"manual release removes member");
                    require(target.isNoAi(),"release restores pre-existing NoAI state");
                    require(!r.minions.recruit(session,boss,target),"manual release has recruitment immunity");
                    for(NexusMinions.Type type:NexusMinions.Type.values())require(r.minions.spawn(session,type,new Vec3(8,65,type.ordinal()*2)),"NPC variant spawned: "+type.name());
                    r.cancel(session);require(r.minions.size()==0,"cancel removes summoned NPCs");
                    r.deactivate(boss);require(r.sessions().isEmpty()&&r.effectCount()==0,"deactivation clears sessions and scheduler");
                    require(boss.getMaxHealth()==20,"deactivation restores original max health");
                    finish(r,null);
                }
                for(Mob m:targets){if(m.isAlive()){m.setHealth(1000);m.setDeltaMovement(Vec3.ZERO);}}
            }catch(Throwable error){finish(r,error);}
        });
    }
    private void requireBudget(NexusRuntime r){if(r.effectCount()>r.config().maxEffects)throw new AssertionError("Effect budget exceeded: "+r.effectCount());}
    private void next(NexusRuntime r){
        if(!session.valid()||r.session(boss)!=session)throw new AssertionError("Test boss was removed before cast; check forced test chunks");
        r.cancel(session);session.recruitment=false;r.minions.clear(session);stage++;
        if(stage>19)return;
        for(int i=0;i<targets.size();i++){Mob m=targets.get(i);m.setPos(5+(i/5)*3,65,-6+(i%5)*3);m.setHealth(1000);m.removeAllEffects();}
        boss.setPos(0,65,0);boss.setHealth(600);boss.lookAt(net.minecraft.commands.arguments.EntityAnchorArgument.Anchor.EYES,new Vec3(8,66,0));
        session.busyUntil=r.now();session.ai=true;damageStart=r.damageEvents;
        require(r.cast(boss,Ability.values()[stage]),"cast accepted: "+Ability.values()[stage].id());session.ai=false;
        require(!r.cast(boss,Ability.values()[stage]),"busy/cooldown gate rejects repeated cast: "+Ability.values()[stage].id());
        stageStart=r.now();
    }
    private void finish(NexusRuntime r,Throwable error){
        if(finished)return;finished=true;
        try{
            if(error!=null){results.add("FAIL "+error);NexusMod.LOG.error("NEXUS VERIFICATION FAILED",error);}
            else {results.add("PASS effect budget remained bounded");results.add("VERIFICATION PASSED");NexusMod.LOG.info("NEXUS VERIFICATION PASSED ({} assertions)",results.size());}
            Files.writeString(Path.of("nexus-verification.txt"),String.join("\n",results)+"\n");
        }catch(Exception ignored){}
        if(r!=null){r.stopAll();r.server.halt(false);}
    }
}
