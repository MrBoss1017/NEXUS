package com.mrboss.nexus;

import com.mojang.brigadier.arguments.BoolArgumentType;
import com.mojang.brigadier.arguments.StringArgumentType;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.minecraft.commands.Commands;
import net.minecraft.commands.CommandSourceStack;
import net.minecraft.commands.arguments.EntityArgument;
import net.minecraft.network.chat.Component;
import net.minecraft.server.permissions.Permissions;
import net.minecraft.world.entity.EntitySpawnReason;
import net.minecraft.world.entity.EntityTypes;
import net.minecraft.world.entity.ai.attributes.Attributes;
import net.minecraft.world.item.ItemStack;
import java.util.Locale;

public final class NexusCommands {
    private NexusCommands() {}
    private static boolean op(CommandSourceStack source){return source.permissions().hasPermission(Permissions.COMMANDS_GAMEMASTER);}
    private static NexusRuntime runtime(){return NexusMod.runtime();}
    public static void register(){
        CommandRegistrationCallback.EVENT.register((dispatcher,access,environment)->{
            var root=Commands.literal("nexus").executes(c->{
                c.getSource().sendSuccess(()->Component.literal("Nexus: activate, menu, cast <power>, ai, minions, infection, clone, free, cancel, deactivate, status. Operator: kit, reload, summon, clear."),false);return 1;
            });
            root.then(Commands.literal("activate").executes(c->runtime().activate(c.getSource().getPlayerOrException(),false)?1:0));
            root.then(Commands.literal("menu").executes(c->{NexusMenu.open(c.getSource().getPlayerOrException());return 1;}));
            root.then(Commands.literal("deactivate").executes(c->{runtime().deactivate(c.getSource().getPlayerOrException());return 1;}));
            root.then(Commands.literal("cast").then(Commands.argument("power",StringArgumentType.word())
                .suggests((c,b)->{for(Ability a:Ability.values())b.suggest(a.id());return b.buildFuture();})
                .executes(c->{
                    String id=StringArgumentType.getString(c,"power");
                    try{return runtime().cast(c.getSource().getPlayerOrException(),Ability.valueOf(id.toUpperCase(Locale.ROOT)))?1:0;}
                    catch(IllegalArgumentException e){c.getSource().sendFailure(Component.literal("Unknown Nexus power: "+id));return 0;}
                })));
            root.then(Commands.literal("clone").executes(c->runtime().minions.cloneAttack(c.getSource().getPlayerOrException())?1:0));
            root.then(Commands.literal("free").executes(c->{runtime().minions.release(c.getSource().getPlayerOrException().getUUID(),true);return 1;})
                .then(Commands.argument("player",EntityArgument.player()).requires(NexusCommands::op)
                    .executes(c->{runtime().minions.release(EntityArgument.getPlayer(c,"player").getUUID(),true);return 1;})));
            for(String flag:new String[]{"ai","minions","infection"})root.then(Commands.literal(flag)
                .then(Commands.argument("enabled",BoolArgumentType.bool()).executes(c->{
                    var s=runtime().session(c.getSource().getPlayerOrException());if(s==null){c.getSource().sendFailure(Component.literal("Awaken the Nexus first."));return 0;}
                    boolean enabled=BoolArgumentType.getBool(c,"enabled");
                    switch(flag){case "ai"->s.ai=enabled;case "minions"->runtime().minions.recruitment(s,enabled);case "infection"->runtime().minions.infection(s,enabled);}
                    c.getSource().sendSuccess(()->Component.literal(flag+": "+enabled),false);return 1;
                })));
            root.then(Commands.literal("cancel").executes(c->{var s=runtime().session(c.getSource().getPlayerOrException());if(s!=null)runtime().cancel(s);return 1;}));
            root.then(Commands.literal("intro").executes(c->{var s=runtime().session(c.getSource().getPlayerOrException());if(s!=null)runtime().intro(s);return 1;}));
            root.then(Commands.literal("status").executes(c->{c.getSource().sendSuccess(()->Component.literal("Nexus: "+runtime().sessions().size()+" bosses · "+runtime().effectCount()+" active effects · "+runtime().minions.size()+" allies"),false);return 1;}));
            root.then(Commands.literal("kit").requires(NexusCommands::op).executes(c->{
                var p=c.getSource().getPlayerOrException();for(var item:NexusItems.ALL){var stack=new ItemStack(item);if(!p.getInventory().add(stack))p.level().addFreshEntity(new net.minecraft.world.entity.item.ItemEntity(p.level(),p.getX(),p.getY()+.5,p.getZ(),stack));}return 1;
            }));
            root.then(Commands.literal("reload").requires(NexusCommands::op).executes(c->{
                try{runtime().reload();c.getSource().sendSuccess(()->Component.literal("Nexus config reloaded. Existing casts retain their captured timing; health changes apply on next activation."),true);return 1;}
                catch(Exception ex){c.getSource().sendFailure(Component.literal("Nexus config rejected; previous configuration is still active: "+ex.getMessage()));return 0;}
            }));
            root.then(Commands.literal("clear").requires(NexusCommands::op).executes(c->{runtime().stopAll();c.getSource().sendSuccess(()->Component.literal("All Nexus encounters ended."),true);return 1;}));
            root.then(Commands.literal("summon").requires(NexusCommands::op).executes(c->{
                var level=c.getSource().getLevel();var mob=EntityTypes.WITHER_SKELETON.create(level,EntitySpawnReason.COMMAND);
                if(mob==null)return 0;
                mob.setPos(c.getSource().getPosition().add(3,0,0));mob.setCustomName(Component.literal("Nexus Avatar"));mob.setCustomNameVisible(true);mob.setPersistenceRequired();mob.addTag("nexus_ephemeral");
                mob.getAttribute(Attributes.ATTACK_DAMAGE).setBaseValue(0);
                if(!runtime().activate(mob,true)){mob.discard();return 0;}
                var s=runtime().session(mob);s.ai=true;
                if(!level.addFreshEntity(mob)){runtime().deactivate(mob);return 0;}return 1;
            }));
            dispatcher.register(root);
        });
    }
}
