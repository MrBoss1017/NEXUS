# Nexus configuration

Place `nexus.toml` in the Minecraft instance or dedicated server's **config** folder. The ZIP includes it as `config/nexus.toml`, ready to extract into the instance root. The server's configuration controls multiplayer gameplay. A client copy only controls that client's integrated single-player server.

Edit using a plain text editor. TOML comments begin with `#`. Run operator command `/nexus reload` afterward. The entire new file is parsed and validated before it replaces the active configuration. Invalid types, non-finite numbers, and out-of-range values reject a reload and keep the previous settings. An invalid file at initial startup stops Nexus initialization with a specific error; it is never silently replaced.

Missing optional keys use built-in defaults. Start with the complete supplied file to preserve its explicit per-attack finisher values. Unknown keys are not consumed; check spelling against the default file. `general.schema_version` must be 1.

## Units and balancing

- **20 ticks = 1 second** at the normal server rate. Lag or changing the tick rate changes real-time pacing.
- Minecraft health points: **2 HP = 1 heart**. `boss_health`, `stomp.damage`, and `minions.support_heal` use Minecraft HP directly.
- Per-ability damage, radius, and knockback are stored in source units. Global scales convert them.
- Ordinary area damage: `damage × source_damage_multiplier × damage_scale × max(0, 1 - distance / radius)`.
- Effective radius: `source radius × range_scale`. Area damage is capped at a 100-block radius. Various visual and targeting geometries also have bounds.
- A lightning strike at its center starts at `220 × 2 × 0.02 = 8.8 HP`, before armor and Minecraft damage immunity.
- Beams, waves, direct support hits, and scripted damage-over-time do not all use distance falloff. Burn uses `burn_source_damage` plus the same global damage scales.
- Minecraft invulnerability frames prevent every overlapping visual pulse from dealing a full hit. They are intentionally preserved.
- Cooldown values are **recovery after the cast duration**. Each power also has a cast lock, and the global cooldown applies across powers. Cancelling does not refund the cooldown.

## Sections

| Section | Controls |
|---|---|
| `general` | Boss HP, unit scales, single-boss limit, activation, target categories, PvP, healing, block damage, intro, shared cooldown, auto-activation UUIDs |
| `ai` | Detection/attack ranges in blocks, decision interval, movement speed |
| `minions` | Player/mob recruitment, touch range/debounce, finale support interval, support healing, NPC lifetime and health/damage scales |
| `infection` | Global clone-role toggle |
| `finale` | Global toggle and ticks per phase; all 34 phases share the configured pacing |
| `status` | Durations, burn frequency/damage, incoming vulnerability multiplier |
| `stomp` | Downward player stomp damage and per-attacker cooldown |
| `visuals` | Sound volume and taunts |
| `performance` | Global particle/effect/NPC caps, target cap per hit, recruit cap per encounter |
| `abilities.<power_id>` | Enabled, source damage/radius/knockback, duration, recovery, warning, pulse count, finisher and lingering damage |

The default file comments document each field. `NexusConfig.java` defines all validation bounds, including boss HP 20–1024; phase duration 20–2400 ticks; 0–4096 particles/tick; 16–2048 active/pending effects; and 1–64 attack pulses.

The source's 6000 HP cannot be used with Minecraft's ordinary max-health attribute limit; this port uses 600 HP by default and permits up to 1024. NPCs retain their individual source HP/damage/recovery ratios, adjusted through `npc_health_scale` and `npc_damage_scale`.

## Examples

To disable attacks against players, edit the existing `[general]` table:

```toml
[general]
affect_players = false
```

To halve damage from its default, set `damage_scale = 0.01` in that same table. Recruitment healing and stomp damage have their own values. Team alliances and the world's PvP rule are also respected.

For a shorter, 3-minute-24-second finale:

```toml
[finale]
enabled = true
phase_ticks = 120
```

To reduce particles while leaving damage mechanics active:

```toml
[performance]
particles_per_tick = 128
```

To disable just one power:

```toml
[abilities.antimatter_annihilation]
enabled = false
```

Edit existing tables instead of appending duplicate TOML table declarations. Disabling a regular power also prevents its corresponding patterns from being launched by future finale phases. Disabling the finale does not cancel a finale already running; use `/nexus cancel` or operator `/nexus clear`.

`general.auto_activate_uuids` accepts UUID strings, for example an array of your own UUIDs. It is empty by default. Auto-activation bypasses the Core requirement but respects the single-boss limit. Roblox usernames are not Minecraft UUIDs.

## Reload and lifecycle details

New settings are read atomically; current casts keep their captured durations and attack values while shared scale/status settings are consulted during hits. Changes to boss HP apply on the next activation. For a completely clean transition, run `/nexus clear`, reload, and awaken again.

Block damage is opt-in and limited to a small 5×3×5 area around an impact. Unbreakable blocks, block entities, unloaded chunks, and positions outside the world border are excluded. No claim/protection-mod integration is provided.

Particles and scheduled effects have global budgets. If the effect budget fills, further scheduled effects are skipped instead of creating an unbounded queue. Particle exhaustion only suppresses additional particles for that tick. Keep conservative limits on shared servers.

The Finale's `duration_ticks`/`windup_ticks`/`pulses` entries do not schedule its phase sequence; `finale.phase_ticks` does. Its recovery and final-blast values are used. Regular attacks use finisher/lingering fields only where those mechanics exist; not every field applies to every geometry.
