package com.mrboss.nexus;

import net.fabricmc.fabric.api.creativetab.v1.FabricCreativeModeTab;
import net.minecraft.core.Registry;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.core.registries.Registries;
import net.minecraft.resources.ResourceKey;
import net.minecraft.network.chat.Component;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.*;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.Block;
import net.minecraft.world.level.block.state.BlockBehaviour;
import net.minecraft.server.level.ServerPlayer;
import java.util.EnumMap;
import java.util.List;
import java.util.ArrayList;
import java.util.function.Function;

public final class NexusItems {
    public static final List<Item> ALL = new ArrayList<>();
    public static final EnumMap<Ability, Item> SIGILS = new EnumMap<>(Ability.class);
    public static final Block CONDUIT = Registry.register(BuiltInRegistries.BLOCK, NexusMod.id("nexus_conduit"),
        new Block(BlockBehaviour.Properties.of().strength(5, 1200).lightLevel(state -> 12)
            .requiresCorrectToolForDrops().setId(ResourceKey.create(Registries.BLOCK, NexusMod.id("nexus_conduit")))));
    public static final Item CORE = register("nexus_core", p -> new ActionItem(p, null, "core"));
    public static final Item CONDUIT_ITEM = register("nexus_conduit", p -> new BlockItem(CONDUIT, p));
    public static final Item CONTROL = register("dominion_codex", p -> new ActionItem(p, null, "menu"));
    public static final Item CLONE_SIGIL = register("clone_sigil", p -> new ActionItem(p, null, "clone"));
    public static final Item RELEASE = register("release_charm", p -> new ActionItem(p, null, "release"));
    private NexusItems() {}
    public static void initialize() {
        for (Ability a : Ability.values()) SIGILS.put(a, register(a.id(), p -> new ActionItem(p, a, "ability")));
        // FabricItemGroup was renamed in modern, unobfuscated Fabric API.
        var tabKey = ResourceKey.create(Registries.CREATIVE_MODE_TAB, NexusMod.id("nexus"));
        Registry.register(BuiltInRegistries.CREATIVE_MODE_TAB, tabKey, FabricCreativeModeTab.builder()
            .title(Component.translatable("itemGroup.nexus"))
            .icon(() -> new ItemStack(CORE)).build());
        net.fabricmc.fabric.api.creativetab.v1.CreativeModeTabEvents.modifyOutputEvent(tabKey).register(output ->
            { for (int i = ALL.size() - 1; i >= 0; i--) output.prepend(ALL.get(i)); });
    }
    private static Item register(String name, Function<Item.Properties, Item> factory) {
        var key = ResourceKey.create(Registries.ITEM, NexusMod.id(name));
        Item item = factory.apply(new Item.Properties().setId(key).stacksTo(1).rarity(Rarity.EPIC).fireResistant());
        Registry.register(BuiltInRegistries.ITEM, key, item); ALL.add(item); return item;
    }
    private static final class ActionItem extends Item {
        private final Ability ability;
        private final String action;
        ActionItem(Properties properties, Ability ability, String action) { super(properties); this.ability = ability; this.action = action; }
        @Override public InteractionResult use(Level level, Player player, InteractionHand hand) {
            if (hand != InteractionHand.MAIN_HAND) return InteractionResult.PASS;
            if (player instanceof ServerPlayer sp && NexusMod.runtime() != null) {
                NexusRuntime r = NexusMod.runtime();
                switch (action) {
                    case "core" -> r.useCore(sp, false);
                    case "menu" -> NexusMenu.open(sp);
                    case "clone" -> r.minions.cloneAttack(sp);
                    case "release" -> r.minions.release(sp.getUUID(), true);
                    default -> r.cast(sp, ability);
                }
            }
            return InteractionResult.SUCCESS;
        }
    }
}
