package com.mrboss.nexus;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerTickEvents;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerEntityEvents;
import net.fabricmc.fabric.api.event.player.UseBlockCallback;
import net.fabricmc.fabric.api.entity.event.v1.ServerLivingEntityEvents;
import net.fabricmc.fabric.api.networking.v1.ServerPlayConnectionEvents;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.resources.Identifier;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.nio.file.Path;

public final class NexusMod implements ModInitializer {
    public static final String ID = "nexus";
    public static final Logger LOG = LoggerFactory.getLogger(ID);
    public static final Path CONFIG_PATH = FabricLoader.getInstance().getConfigDir().resolve("nexus.toml");
    private static NexusRuntime runtime;
    public static NexusRuntime runtime() { return runtime; }
    public static Identifier id(String path) { return Identifier.fromNamespaceAndPath(ID, path); }
    @Override public void onInitialize() {
        NexusStatus.initialize();
        NexusItems.initialize();
        NexusCommands.register();
        ServerLifecycleEvents.SERVER_STARTED.register(server -> {
            try { runtime = new NexusRuntime(server, NexusConfig.read(CONFIG_PATH)); }
            catch (Exception ex) { throw new IllegalStateException("Nexus configuration failed: " + CONFIG_PATH, ex); }
            LOG.info("Nexus ready: 20 abilities and 34 finale phases for Minecraft 26.3");
        });
        ServerTickEvents.END_SERVER_TICK.register(server -> {
            if (runtime != null) runtime.tick();
        });
        ServerLifecycleEvents.SERVER_STOPPING.register(server -> {
            if (runtime != null) runtime.stopAll();
            runtime = null;
        });
        ServerPlayConnectionEvents.JOIN.register((handler, sender, server) -> {
            if (runtime != null && runtime.config().autoActivate.contains(handler.player.getUUID().toString()))
                runtime.activate(handler.player, true);
        });
        ServerPlayConnectionEvents.DISCONNECT.register((handler, server) -> {
            if (runtime != null) runtime.leave(handler.player);
        });
        ServerLivingEntityEvents.AFTER_DEATH.register((entity, source) -> {
            if (runtime != null) runtime.leave(entity);
        });
        ServerEntityEvents.ENTITY_UNLOAD.register((entity, level) -> {
            if (runtime != null && entity instanceof net.minecraft.world.entity.LivingEntity living) runtime.leave(living);
        });
        ServerEntityEvents.ENTITY_LOAD.register((entity, level) -> {
            if (!(entity instanceof net.minecraft.world.entity.LivingEntity living)) return;
            boolean owned = runtime != null && (runtime.session(living) != null || runtime.minions.owner(living) != null);
            if (owned) return;
            // Recovery after a crash: temporary summons must not become orphaned;
            // borrowed vanilla mobs get their original AI flag back on chunk load.
            if (entity.entityTags().contains("nexus_ephemeral")) entity.discard();
            else if (entity instanceof net.minecraft.world.entity.Mob mob && entity.entityTags().contains("nexus_recruited_ai")) {
                mob.setNoAi(entity.entityTags().contains("nexus_previous_no_ai"));
                mob.removeTag("nexus_recruited_ai");mob.removeTag("nexus_previous_no_ai");
            }
        });
        UseBlockCallback.EVENT.register((player, level, hand, hit) -> {
            if (hand != InteractionHand.MAIN_HAND || !level.getBlockState(hit.getBlockPos()).is(NexusItems.CONDUIT))
                return InteractionResult.PASS;
            if (player instanceof ServerPlayer sp && runtime != null) runtime.useCore(sp, true);
            return InteractionResult.SUCCESS;
        });
    }
}
