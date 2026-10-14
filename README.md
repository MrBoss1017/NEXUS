# Nexus: Cosmic Dominion — Fabric 26.3

A Java adaptation of the supplied 11,116-line Nexus Luau script. Play as the Nexus, wield 19 attack powers and the 34-phase Nexus Finale, recruit allies, infect clones, or summon an AI boss encounter.

## Install the binary

1. Install **Minecraft Java 26.3**, **Fabric Loader 0.19.5 or newer**, and **Java 25 or newer**.
2. From `Nexus-26.3-Mod-Package.zip`, copy the two JARs inside `mods/` into your instance's `.minecraft/mods/` folder. The archive includes Nexus 1.0.0 and Fabric API 0.160.6+26.3. Keep only one compatible Fabric API JAR.
3. From `Nexus-26.3-Config-Package.zip`, copy `config/nexus.toml` into `.minecraft/config/nexus.toml`. Nexus also creates this file automatically on first startup if absent.
4. Launch the Fabric profile. Install Nexus and Fabric API on **both the client and the dedicated server** for multiplayer. On a dedicated server, use that server's `mods/` and `config/` directories.

Extracting each archive into the instance root also places its `mods/` or `config/` folder correctly. Do not put the ZIP itself in `mods/`, or put an extra `mods` folder inside `mods`.

## Play

Open the **Nexus: Cosmic Dominion** creative inventory tab. It contains all **25** custom item entries, including the placeable Nexus Conduit.

- Right-click a **Nexus Core** to awaken. After the five-second intro, use it again to open the control panel. Sneak-use the Core to deactivate.
- Right-click a placed **Nexus Conduit** to awaken without carrying a Core. It also opens the panel while active.
- Aim at the ground or an opponent, then right-click an **ability sigil** to cast. The panel offers every power, so survival players do not need 20 separate sigils.
- The **Dominion Codex** opens the panel while awakened. Panel controls toggle AI, recruitment, and infection; replay the intro; cancel the current cast; and deactivate.
- Recruitment spreads by contact and heals the boss by the recruit's current health. Infected players receive a random lightning, fire, or ice clone power, used through the **Clone Sigil** or `/nexus clone`.
- A recruited player can use the **Release Charm** or `/nexus free` to leave and gain five seconds of recruitment immunity. This charm frees recruits; the Core's sneak-use ends a boss possession.
- The Finale has 34 phases and lasts **10 minutes 12 seconds** at the default 20 TPS. It is manually triggered and temporarily enables recruitment.

All casts, hits, ownership, cooldowns, and menu actions are controlled by the server. Cancelling a cast retains its cooldown. Death, disconnect, dimension change, entity unload, and server shutdown clear encounter state.

## Survival crafting

| Item | Ingredients / placement |
|---|---|
| Nexus Core | 3×3 pattern `AEA / SNS / AEA`: A = amethyst shard, E = ender pearl, S = echo shard, N = nether star |
| Nexus Conduit | 3×3 pattern `OAO / ACA / OAO`: O = obsidian, A = amethyst shard, C = Nexus Core |
| Dominion Codex | Shapeless: book + amethyst shard + ender pearl |
| Release Charm | Shapeless: amethyst shard + milk bucket |

The conduit emits light and requires a diamond-tier pickaxe for its drop. Ability sigils and the Clone Sigil are available from the creative tab or `/nexus kit`; their abilities are also accessible through the panel and commands.

## Commands

| Command | Purpose |
|---|---|
| `/nexus activate` | Awaken; requires a carried Core unless creative, an operator, or disabled in config |
| `/nexus menu` | Open the control panel |
| `/nexus cast <power>` | Cast an ID such as `lightning_strike`; tab completion lists all 20 |
| `/nexus ai true/false` | Toggle automatic targeting and attacks |
| `/nexus minions true/false` | Toggle contact recruitment; disabling releases allies |
| `/nexus infection true/false` | Toggle clone roles for recruits |
| `/nexus clone` | Use your assigned clone power |
| `/nexus free` | Leave recruitment |
| `/nexus intro` | Replay the intro while no attack is active |
| `/nexus cancel` | Cancel your current cast and remove summoned NPCs |
| `/nexus deactivate` | End your Nexus possession |
| `/nexus status` | Show encounter, effect, and ally counts |
| `/nexus kit` | Operator: give all custom items |
| `/nexus summon` | Operator: spawn a Nexus Avatar with automatic combat |
| `/nexus clear` | Operator: terminate all Nexus encounters and summoned avatars |
| `/nexus reload` | Operator: validate and reload `config/nexus.toml` |
| `/nexus free <player>` | Operator: free a selected recruit |

Player actions require a player command source; `reload`, `clear`, `status`, and `summon` also work from the console. Operator actions require the game's gamemaster permission.

## Configuration and adaptation

The default config is deliberately balanced for Minecraft: 600 boss HP, 10 studs per block, and source damage multiplied by 0.02 after the source's ×2 damage rule. Armor and Minecraft damage immunity frames still apply. Block destruction is disabled by default.

The original Roblox GUI, world-lighting tweens, meshes, animation rig, and private sound IDs are adapted to a native inventory panel, boss bar, particle geometry, and Minecraft sounds. Five NPC variants use vanilla models with custom names, stats, effects, and server-controlled attacks. See [the detailed porting map](docs/PORTING_MAP.md), including the exact 34-phase order and deliberate behavior repairs. This is a gameplay adaptation, not an audiovisual replica.

[CONFIG.md](docs/CONFIG.md) describes the commented TOML sections, units, reload behavior, and examples.

## Build from full source

The mod package includes the entire project under `source/`, with Java sources, assets, data, Gradle wrapper, tests, scripts, and the unchanged supplied Luau file under `reference/`.

Use JDK 25. The normal Fabric build uses Loom 1.17.21 and Gradle 9.6.0:

If working from the extracted mod package, enter its `source/` directory first.

```sh
./gradlew clean build
./gradlew bundle
```

Windows: `gradlew.bat clean build` and `gradlew.bat bundle`.

The JAR is written to `build/libs/nexus-1.0.0.jar`. Both ZIPs are written to `build/packages/`. `bundle` runs the build and unit tests before packaging. Minecraft 26.3 is unobfuscated, so the project uses Fabric's non-remapping Loom plugin and standard Java dependency configurations.

An additional build route, used to produce the included release, needs **Python 3.10+ and JDK 25**:

```sh
python scripts/build_standalone.py --bundle
# After its dependency cache has been populated:
python scripts/build_standalone.py --offline --bundle
```

This downloads pinned official Minecraft/Fabric and Maven dependencies, verifies Mojang's server checksum, compiles against the actual game APIs with `javac`, runs the JUnit suite, embeds the TOML parser, and packages the release. Its `.standalone/` cache is excluded from the ZIPs. No Minecraft or Java binaries are redistributed.

The delivery environment prohibits the Unix-domain-socket probe used during Loom initialization. Therefore a full Gradle execution could not be completed here; the included binary was compiled with the standalone route and loaded into an actual Minecraft 26.3 Fabric server. See [VALIDATION.md](docs/VALIDATION.md) for the test scope and limitations.

## Layout

| Path | Responsibility |
|---|---|
| `src/main/java/com/mrboss/nexus/` | Registries, commands, config, abilities, sessions, scheduler, minions, menu |
| `src/main/java/com/mrboss/nexus/mixin/` | Healing restriction, stun/freeze jump prevention, incoming vulnerability |
| `src/main/resources/assets/nexus/` | Custom textures, item definitions, models, blockstate, language |
| `src/main/resources/data/` | Recipes, conduit loot table, mining tags |
| `src/main/resources/nexus-default.toml` | Packaged commented defaults |
| `src/test/` | JUnit config and cooldown tests |
| `src/verification/` | Separate, opt-in integration mod; never in the release JAR |
| `scripts/verify_server.py` | Disposable local-server verification runner |
| `scripts/generate_assets.py` | Optional pixel-asset regeneration; requires Pillow |

## Upstream technical references

- [Fabric for Minecraft 26.3](https://www.fabricmc.net/2026/09/15/263.html)
- [Fabric development documentation](https://docs.fabricmc.net/)
- [Fabric Maven](https://maven.fabricmc.net/)
- [Fabric Loader version metadata](https://meta.fabricmc.net/v2/versions/loader/26.3/0.19.5/profile/json)

New port code and original pixel assets use the MIT license in `LICENSE`. Third-party components retain their own licenses; see `THIRD_PARTY_NOTICES.md`. The provided Luau reference remains under its original rights.
