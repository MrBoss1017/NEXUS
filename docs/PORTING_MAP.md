# Luau-to-Minecraft porting map

Source: `reference/Nexus-original.luau`, unchanged from the supplied `Nexus 11k(1).luau` (11,116 lines). SHA-256: `0e7c2b31a022689a55f4f165fa6cbc9845f250b2d7976b49eacaa60dd8e07ffc`. Line references below refer to that file.

The source is a Roblox **server Script**. It possesses a player rather than creating an independent boss character. The main Minecraft path preserves this: the player awakens the Nexus and controls powers. The operator-only summoned avatar is an additional Minecraft encounter option.

## Core state and behavior

| Source state / function | Java adaptation |
|---|---|
| `nexusInUse`, `currentNexusPlayer` | `NexusRuntime.sessions`; default single-boss gate, optional multiple sessions |
| `Attack`, `DEAD`, `canUseAttack()` | Alive/session checks, server-tick cast lock, `CooldownGate`, global six-tick minimum |
| `AttackCooldowns.* = tick()` | Explicit per-ability recovery measured from cast completion; retained on cancellation |
| `HUMANOID.MaxHealth = 6000` (line 199) | Transient max-health attribute modifier; default 600 HP; removed on release |
| `AUTO_SPAWN_PLAYER_NAME` (line 59) | Configured Minecraft UUID allowlist; empty by default |
| `ClickDetector` on script parent | Right-clickable Nexus Conduit block and portable Nexus Core |
| `GetNearestTarget`, `ExecuteAIAttack` | Server-side nearest eligible target, pursuit, attack-range gating and random available power |
| `ApplyDamage`, `ApplyAoE` (lines 833, 1437) | Scaled magic damage, source ×2 multiplier, radial distance falloff, bounded target queries |
| `BodyVelocity`, `BodyPosition` | Clamped entity impulses, pull fields, levitation |
| `Touched` projectile handlers | Segment-based entity and block collision; prevents fast-projectile tunnelling |
| `task.wait`, coroutines, `Debris` | Bounded tick scheduler with cast-generation cancellation and lifetime expiry |
| `MinionConfig` (line 344) | Per-session owner/parent links, contact recruitment, boss healing, friendly-fire exclusion |
| `recruitMinion` / `freeMinion` | Parent-chain visuals; released descendants reparent to boss; optional five-second release immunity |
| `CurrentFinalePhase`, `grantMinionAbility` | Phase-indexed support attacks every five seconds during the finale |
| `InfectionConfig`, clone GUI helpers | Explicit panel/command toggle; random weakened lightning/fire/ice power for infected recruits |
| `NPCConfig` / `NPCTypes` | Five named vanilla-model variants with source HP/damage/cooldown ratios and custom server attacks |
| `handlePlayerStomp` (line 10442) | Downward player-on-boss stomp, bounce, per-attacker 40-second cooldown; default nine Minecraft HP |
| `CreateModernGUI` (line 10528) | Server-controlled 27-slot native inventory menu: 20 powers and seven controls |
| Boss HUD, health colors | Nearby synchronized boss bar showing HP, active power and phase; purple/yellow/red health thresholds |
| Taunts / custom chat | Nearby in-game chat and action-bar feedback |
| `SOUNDS`, Lighting/TweenService | Minecraft sound events, bounded particle geometry, finale boss-bar darkness |

Damage scales, timing, targeting, recruitment, performance budgets, and all powers are configurable. AI detection and attack ranges use Minecraft block units and are tuned independently from the source's 100-/30-stud defaults.

## Every power

The function names and order are retained. Each power has a sigil, menu action, command ID, and TOML table. Minecraft geometry and pulse counts are bounded; the implementation does not attempt to reproduce thousands of temporary Roblox Parts.

| Power / config ID | Source function begins | Implemented mechanics |
|---|---:|---|
| **Lightning Strike** / `lightning_strike` | 1878 | Telegraphed chained/scattered lightning, stun and residual ground damage. |
| **Meteor Shower** / `meteor_shower` | 2040 | Falling meteors with swept collisions, impact damage and burning fields. |
| **Dimensional Rifts** / `dimensional_rifts` | 2493 | A ring of rifts fires aimed projectiles and collapses into explosions. |
| **Arcane Devastation** / `arcane_devastation` | 2676 | Warning markers erupt into arcane columns, vulnerability and residual fields. |
| **Inferno Tornado** / `inferno_tornado` | 2924 | A moving fire vortex pulls, lifts and burns targets before detonating. |
| **Cosmic Annihilation** / `cosmic_annihilation` | 3166 | An overhead core charges and bombards scattered ground targets. |
| **Quantum Slice** / `quantum_slice` | 3397 | Rotating horizontal slices hit along clipped beams, followed by a radial finisher. |
| **Stellar Convergence** / `stellar_convergence` | 3546 | A linked ring of stellar cores fires projectiles and detonates. |
| **Void Storm** / `void_storm` | 3856 | Void nodes launch slower blinding projectiles and collapse. |
| **Plasma Nova** / `plasma_nova` | 4211 | A central vortex pulls enemies inward and releases expanding damage waves. |
| **Cryo Blast** / `cryo_blast` | 4404 | A fan of freezing beams ends with outward ice projectiles. |
| **Gravity Collapse** / `gravity_collapse` | 4654 | A gravity well pulls and damages targets, then launches them upward. |
| **Plasma Cascade** / `plasma_cascade` | 4872 | Linked plasma nodes fire stunning projectiles and explode together. |
| **Reality Shatter** / `reality_shatter` | 5161 | Persistent fractured ground applies vulnerability, followed by collapse bursts. |
| **Solar Flare Burst** / `solar_flare_burst` | 5384 | An elevated solar core projects burning beams and a final explosion. |
| **Temporal Distortion** / `temporal_distortion` | 5590 | Temporal fields slow movement and velocity, then collapse with stun. |
| **Volcanic Eruption** / `volcanic_eruption` | 5798 | Warning vents erupt, throw lava-like projectiles, and leave burning ground. |
| **Antimatter Annihilation** / `antimatter_annihilation` | 6113 | A pull-in vortex applies vulnerability, releases waves and detonates. |
| **Typhoon Cyclone** / `typhoon_cyclone` | 6319 | Multiple moving cyclones lift targets, emit lightning and collapse. |
| **Nexus Finale** / `nexus_finale` | 7309 | All 34 phase states, combined power patterns, minion support, five NPC variants and final blast. |

The source has **19 regular attack functions plus NexusFinale = 20 powers**. Its numeric comments skip values; they are not an additional implemented ability.

## Finale sequence

The source labels the finale as “30 phases” near line 7308, but implements **34**. All 34 are represented below in their original progression. Display labels are shortened in places. Each phase normally lasts 360 ticks; finale patterns use up to six pulses, with bounded overlaps. These are combinations of the shared Minecraft attack geometries, not literal copies of every nested effect in each source phase.

| Phase | In-game title | Shared power patterns | NPC support |
|---:|---|---|---|
| 1 | The Awakening of Chaos | Awakening helix and boss-bar darkness | — |
| 2 | Elemental Chaos | lightning strike + cryo blast | — |
| 3 | Meteor Apocalypse | meteor shower | — |
| 4 | Dimensional Rift Chaos | dimensional rifts | — |
| 5 | Plasma Nova | plasma nova | — |
| 6 | Quantum Collapse | quantum slice | — |
| 7 | Inferno Apocalypse | inferno tornado | — |
| 8 | The Convergence | stellar convergence | — |
| 9 | Ultimate Cataclysm | cosmic annihilation + lightning strike | — |
| 10 | Singularity Vortex | gravity collapse | Dark Herald |
| 11 | Reality Fracture | reality shatter + dimensional rifts | Void Sentinel |
| 12 | Elemental Convergence | volcanic eruption + cryo blast | Elemental Titan |
| 13 | Shadow Apocalypse | void storm | Shadow Wraith |
| 14 | Cosmic Storm | meteor shower + solar flare burst | Cosmic Destroyer |
| 15 | Nexus Ascension | cosmic annihilation + plasma cascade | Cosmic Destroyer |
| 16 | Apocalyptic Lightning Storm | lightning strike | — |
| 17 | Endless Meteor Apocalypse | meteor shower | — |
| 18 | Dimensional Chaos | dimensional rifts | — |
| 19 | Arcane Annihilation | arcane devastation | — |
| 20 | Inferno Finale | inferno tornado | — |
| 21 | Cosmic Annihilation Finale | cosmic annihilation | — |
| 22 | Quantum Slice Finale | quantum slice | — |
| 23 | Plasma Vortex Convergence | plasma nova + plasma cascade | — |
| 24 | Glacial Storm | cryo blast | — |
| 25 | Gravitational Singularity | gravity collapse | — |
| 26 | Reality Fractures | reality shatter | — |
| 27 | Solar Core Ignition | solar flare burst | — |
| 28 | Magma Chambers | volcanic eruption | — |
| 29 | Antimatter Cascade | antimatter annihilation | — |
| 30 | Gravity Nexus | gravity collapse + temporal distortion | — |
| 31 | Void Singularity | void storm + dimensional rifts | — |
| 32 | The Four Elements | volcanic eruption + cryo blast | Elemental Titan |
| 33 | Everything at Once | plasma nova + lightning strike | Dark Herald |
| 34 | Beyond Ultimate | antimatter annihilation + reality shatter | Cosmic Destroyer |

The last phase adds the configured large finishing blast. Later phases increase pattern damage and introduce additional attacks. NPCs have bounded lifetimes and global spawn limits. Finale completion or cancellation restores the prior recruitment flag and clears summoned NPCs; turning recruitment off releases recruits.

## Status effects

| Source effect | Minecraft effect | Default |
|---|---|---|
| Stun | Custom harmful effect; movement speed zero, grounded jumps and Nexus casts blocked | 2 seconds |
| Burn | Server-owned recurring scaled magic damage and flame particles; no fire-block placement | 4 seconds; pulse every 0.5 seconds |
| Freeze | Custom harmful effect; movement speed zero, grounded jumps and Nexus casts blocked | 3 seconds |
| Slow | Vanilla Slowness IV | 5 seconds |
| Weakness | Custom **Vulnerable** effect; incoming damage ×1.5 | 6 seconds |
| Blind | Vanilla Blindness | 4 seconds |
| Levitate | Vanilla Levitation | 3 seconds |

The source's “Weakness” increases damage taken, so vanilla Weakness, which reduces outgoing melee damage, would implement the wrong mechanic. The port uses vulnerability instead; it applies to incoming damage generally. Rooted entities can still be moved by knockback and can use ordinary non-Nexus attacks. Existing vanilla movement rules remain active.

## NPC variants

| Variant | Minecraft model | Source HP | Default Minecraft HP | Source damage | Attack recovery |
|---|---|---:|---:|---:|---:|
| Dark Herald | Zombie | 800 | 80 | 35 | 2 seconds |
| Void Sentinel | Wither Skeleton | 1000 | 100 | 45 | 2.5 seconds |
| Elemental Titan | Husk | 1500 | 150 | 60 | 3 seconds |
| Shadow Wraith | Stray | 600 | 60 | 30 | 1.5 seconds |
| Cosmic Destroyer | Piglin Brute | 1200 | 120 | 50 | 2 seconds |

NPC damage also uses the global damage scales. NPCs use named models, colored effects, projectiles, and manual pursuit in place of the source's welded Roblox rigs. Recruited ordinary mobs have their original AI state restored on release; summoned variants are discarded. Ephemeral-entity tags provide orphan cleanup after a server interruption.

## Deliberate repairs and Minecraft differences

- The Luau server script explicitly disables `UserInputService`, leaving its keyboard controls inactive. This port provides working right-click items, server-controlled menu actions, and commands without custom keybindings.
- Several source status lookups use `Character` where cached entries contain `Model`. Effects in this port are attached to actual `LivingEntity` instances.
- The source records per-power cooldown timestamps without consistently using them to gate attacks. This port enforces configurable recovery while preserving the shared cast lock and minimum interval.
- Clone/infection visual and GUI functions exist in the source but are not connected to a complete usable control path. This port connects infection to recruitment and provides clone actions. It does not copy Roblox GUI layout or animations.
- Health restoration restrictions use a real `heal` interception. Recruitment intentionally heals directly, preserving its exception. The default prevents other `heal` calls for bosses and infected recruits; custom mods that write health directly can bypass it.
- Cleanup runs for cancellation, deactivation, death, disconnect, dimension/entity unload, and shutdown. Session modifiers are transient. Summoned NPCs have lifetime caps. Cleanup functions present but unused in the source are made effective.
- Ranges, velocity, time, and damage are balanced for Minecraft. The default finale lasts 10:12 at 20 TPS; individual source waits and simultaneous Parts are not reproduced one for one.
- Minecraft armor, damage immunity frames, team alliances, creative/spectator immunity and PvP rules apply. Targeting passive mobs is disabled by default. Recruitment can extend to mobs as well as players.
- No global day/night changes, global gravity changes, terrain-wide lighting rewrite, camera shaking, custom humanoid rig, floating numeric damage GUI, copied Roblox sounds, or custom NPC model is included. The corresponding presentation uses particles, standard sounds, status icons, boss bars and local messages.
- The custom creative tab uses **`FabricCreativeModeTab`**, the current 26.3 API equivalent of the requested historical `FabricItemGroup` API. All 25 custom entries are populated and checked on the real server API.

## Architecture and performance

`NexusMod` registers lifecycle hooks and content. `NexusRuntime` owns the single server-thread scheduler, sessions and damage/targeting rules. `AbilityEngine` implements reusable geometry; `FinaleTimeline` composes it. `NexusMinions` owns recruitment and NPCs. `NexusSession` owns health modification, the boss bar and cooldowns. `NexusConfig` loads validated TOML snapshots. `NexusMenu` handles every click on the server. `NexusStatus` and a narrowly scoped mixin implement status/healing rules.

Scheduled effects carry an owner, start tick, lifetime and session generation. Cancellation increments the generation, invalidating nested callbacks. The active queue is processed as a snapshot, so synchronous death/unload callbacks can safely remove effects. A zero-delay task begins on the following tick, avoiding missed one-tick callbacks. Particle and effect budgets apply across sessions, while target queries and NPC counts are bounded.
