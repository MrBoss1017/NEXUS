package com.mrboss.nexus;

import net.minecraft.core.component.DataComponents;
import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.SimpleContainer;
import net.minecraft.world.SimpleMenuProvider;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.ChestMenu;
import net.minecraft.world.inventory.ContainerInput;
import net.minecraft.world.inventory.MenuType;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.component.ItemLore;
import java.util.List;

/** Vanilla chest protocol provides a working, server-controlled control panel on both sides. */
public final class NexusMenu extends ChestMenu {
    private final ServerPlayer viewer;
    private final SimpleContainer icons;
    private long nextClick;
    private NexusMenu(int id,ServerPlayer player){
        this(id,player,new SimpleContainer(27));
    }
    private NexusMenu(int id,ServerPlayer player,SimpleContainer icons){
        super(MenuType.GENERIC_9x3,id,player.getInventory(),icons,3);this.viewer=player;this.icons=icons;refresh();
    }
    public static void open(ServerPlayer player){
        if(NexusMod.runtime()==null)return;
        if(NexusMod.runtime().session(player)==null){NexusRuntime.tell(player,"Awaken using the Nexus Core first.");return;}
        player.openMenu(new SimpleMenuProvider((id,inventory,p)->new NexusMenu(id,player),Component.literal("NEXUS · Cosmic Dominion")));
    }
    private static ItemStack icon(Item item,String title,String...lines){
        var stack=new ItemStack(item);stack.set(DataComponents.CUSTOM_NAME,Component.literal(title));
        stack.set(DataComponents.LORE,new ItemLore(java.util.Arrays.stream(lines).map(Component::literal).map(c->(Component)c).toList()));return stack;
    }
    private void refresh(){
        var r=NexusMod.runtime();if(r==null)return;var s=r.session(viewer);if(s==null)return;
        for(Ability a:Ability.values()) {
            var power=r.config().power(a);long remaining=s.cooldowns.remaining(a,r.now());
            icons.setItem(a.ordinal(),icon(NexusItems.SIGILS.get(a),a.title,
                !power.enabled()?"Disabled by config":remaining>0?"Cooldown: "+String.format(java.util.Locale.ROOT,"%.1f s",remaining/20.0):"Click to cast",
                "Aim before opening the panel.","Right-click its sigil for direct casting."));
        }
        icons.setItem(20,icon(Items.COMPASS,"AI: "+(s.ai?"ON":"OFF"),"Automatic pursuit and powers","Finale is always manual."));
        icons.setItem(21,icon(Items.LEAD,"Recruitment: "+(s.recruitment?"ON":"OFF"),"Contact recruits allies and heals you.","Turning off frees all allies."));
        icons.setItem(22,icon(Items.FERMENTED_SPIDER_EYE,"Infection: "+(s.infection?"ON":"OFF"),"Recruits gain a random clone power."));
        icons.setItem(23,icon(Items.AMETHYST_SHARD,"Replay Intro","Requires no active cast."));
        icons.setItem(24,icon(Items.BARRIER,"Cancel Current Cast","Cooldown is retained."));
        icons.setItem(25,icon(Items.PAPER,"Status: "+(int)viewer.getHealth()+" HP","Minions: "+r.minions.count(s),"Phase: "+s.phase+" / 34"));
        icons.setItem(26,icon(NexusItems.RELEASE,"Release Nexus Powers","Restores ordinary max health.","Clears minions, casts and boss bar."));
    }
    @Override public void clicked(int slot,int button,ContainerInput input,Player player){
        var r=NexusMod.runtime();if(r==null||player!=viewer||r.now()<nextClick)return;
        var s=r.session(viewer);if(s==null){viewer.closeContainer();return;}
        if(slot<0||slot>=27||input!=ContainerInput.PICKUP||(button!=0&&button!=1))return;
        nextClick=r.now()+4;
        if(slot<20){r.cast(viewer,Ability.values()[slot]);viewer.closeContainer();return;}
        switch(slot){
            case 20->s.ai=!s.ai;
            case 21->r.minions.recruitment(s,!s.recruitment);
            case 22->r.minions.infection(s,!s.infection);
            case 23->r.intro(s);
            case 24->r.cancel(s);
            case 26->{r.deactivate(viewer);viewer.closeContainer();return;}
            default->{ }
        }
        refresh();broadcastChanges();
    }
    @Override public ItemStack quickMoveStack(Player player,int slot){return ItemStack.EMPTY;}
    @Override public boolean stillValid(Player player){return player==viewer&&NexusMod.runtime()!=null&&NexusMod.runtime().session(viewer)!=null;}
    @Override public void broadcastChanges(){refresh();super.broadcastChanges();}
}
