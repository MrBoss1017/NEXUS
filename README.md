<p align="center">
  <img width="3584" height="1184" alt="banner" src=<img width="763" height="236" alt="banner2" src="https://github.com/user-attachments/assets/1587fabb-eef8-4d3a-824b-aca73ab24ea3" />
 />
</p>

<p align="center">
  <h3 align="center">Reality bends to the core.</h3>
</p>

**Nineteen cosmic powers. A 34-phase celestial finale. A world that remembers the awakening.**

[![Minecraft 26.3](https://img.shields.io/badge/Minecraft-26.3-5B8C5A?style=flat-square)](https://www.minecraft.net/)
[![Loader Fabric](https://img.shields.io/badge/Loader-Fabric-dbd0b4?style=flat-square)](https://fabricmc.net/)
[![Java 25](https://img.shields.io/badge/Java-25-ED8B00?style=flat-square)](https://openjdk.org/)
[![License GPL-3.0-only](https://img.shields.io/badge/License-GPL--3.0--only-7B68EE?style=flat-square)](LICENSE)
[![build passing](https://img.shields.io/badge/build-passing-2cbe4e?style=flat-square)](#validation-and-limitations)

[Get started](#installation) · [The arsenal](#the-arsenal) · [34-Phase finale](#the-34-phase-ultimate-finale) · [Configuration](#configuration-and-limits) · [Build & test](#building-from-source)

**[Download NEXUS v1.1.0](https://github.com/MrBoss1017/NEXUS/releases/tag/v1.1.0)**

</div>

---

**NEXUS: Cosmic Dominion** is a Minecraft **26.3** Fabric mod adapted from the original Nexus Luau script, turning destructive cosmic abilities and high-speed entity warfare into a directed spectacle. Awaken the Nexus Core, command nineteen distinct attack abilities, recruit protected allies, or unleash a 34-phase ultimate finale—then walk through the excavated craters left behind.

The spectacle has teeth. Combat state, ability cooldowns, damage calculation, ally recruitment, infection/clone logic, NPC summoning, and terrain excavation belong to the server. The client drives the custom animated 3D VFX, awakening and finale cutscenes, dynamic camera movement, screen shake, and the interactive control menu.

This repository includes the full Java source, custom 3D assets, recipes, default TOML configurations, Gradle wrapper, and standalone Python build pipelines. Automated unit, server, and graphical-client verifications are detailed in [Validation and limitations](#validation-and-limitations).

## What NEXUS brings to Minecraft

* **Nineteen distinct attack abilities:** Cast destructive cosmic techniques directly through individual ability sigils or the interactive in-game control menu.
* **A 34-phase ultimate finale:** A continuous, multi-stage apocalyptic sequence combining custom animated 3D VFX, directed camera work, and massive terrain devastation.
* **The 600-HP Nexus Form:** Awaken into a high-durability cosmic state featuring custom status effects and optional automatic combat engagement.
* **Ally recruitment, infection, and summons:** Recruit protected allies (completely immune to your collateral damage), infect or clone targets, and deploy **five summoned NPC variants**.
* **Persistent terrain deformation:** Permanent crater excavation and beam terrain destruction across the world, damaging hostile, passive, and neutral mobs by default while preserving recruited allies.
* **Directed, skippable cinematography:** Full awakening and finale cutscenes with instant skip (`V`) and toggle (`N`) controls so combat flow remains responsive.
* **Dedicated Creative Tab:** 25 custom item and block entries organized in a single creative inventory tab for immediate access.

## The arsenal

### THE NEXUS CORE & AWAKENED FORM

**Ascend beyond baseline mortality.**

The Nexus Core is the central catalyst of the mod. Right-clicking awakens the operator into the **600-HP Nexus Form**, applying cosmic status effects, activating automatic combat routines, and unlocking the radial control interface. Sneak-using the Core safely deactivates the form and restores standard player state.

While awakened, the server continuously evaluates nearby entities—routing automatic strikes toward hostile, neutral, or passive targets while strictly shielding recruited allies from friendly fire.

### COSMIC ABILITY SIGILS (19 VARIATIONS)

**Precision devastation, bound to sigils.**

Each of the 19 attack abilities can be triggered on demand via dedicated sigils or the Nexus control menu. Beam attacks carve continuous trenches through loaded terrain; kinetic and stellar impacts excavate permanent craters and apply custom status effects. Custom animated 3D VFX synchronize across clients in multiplayer.

### RECRUITMENT, INFECTION & THE FIVE SUMMONS

**Command a cosmic vanguard.**

NEXUS extends beyond solo bombardment into battlefield control. Operators can infect targets to generate clones, recruit existing entities into a protected faction list, and summon five specialized NPC variants that engage targets autonomously under server authority.

### System reference values

Bundled defaults at nominal **20 TPS** under `v1.1.0` configuration:

| System / Component | Specification | Authority / Behavior |
| :--- | :--- | :--- |
| **Nexus Form Health** | 600 HP | Server-authoritative max health pool upon awakening |
| **Active Attack Abilities** | 19 Abilities | Castable via sigils or Nexus Control Menu |
| **Ultimate Finale** | 34 Phases | Sequential multi-stage VFX, camera, and excavation timeline |
| **Summoned NPC Variants** | 5 Archetypes | Autonomous allied combat entities |
| **Creative Registry** | 25 Entries | Custom items, ability sigils, and block entries |

## The 34-phase ultimate finale

The Ultimate Finale executes a 34-phase cosmic sequence combining progressive 3D visual stages, camera movement, and terrain excavation.

* **Cutscene Control:** Press `V` at any point to skip the active cutscene presentation, or press `N` to toggle cutscene playback globally.
* **Terrain & Entity Rules:** By default, both terrain destruction and passive-mob damage are active during ability and finale execution (`config/nexus.toml`). Recruited allies remain protected throughout all 34 phases.

## Requirements

| Component | Project target |
| :--- | :--- |
| **Minecraft** | **26.3 only** |
| **Java** | **25+** JDK for development; Java 25+ required at runtime |
| **Fabric Loader** | **0.19.5+** |
| **Fabric API** | **0.160.6+26.3** *(included in the mod release package)* |
| **Launcher** | Any launcher supporting Minecraft Java with Fabric, including the official Minecraft Launcher |
| **Multiplayer** | Install **Nexus** and **Fabric API** on **both clients and the server** |

## Installation

1. Create a **Minecraft 26.3 Fabric** instance using **Java 25+** and **Fabric Loader 0.19.5+**.
2. **Upgrading:** Remove any older Nexus JAR files from `.minecraft/mods/` before upgrading to `v1.1.0`.
3. Extract the supplied JARs (**Nexus `v1.1.0`** and the included **Fabric API `0.160.6+26.3`**) into `.minecraft/mods/`.
4. Extract both TOML configuration files (`nexus.toml` and `nexus-client.toml`) into `.minecraft/config/`.
5. For multiplayer servers, install both the Nexus JAR and Fabric API JAR in the server's `mods/` directory and place `nexus.toml` in the server's `config/` directory.

## Controls and first awakening

Locate the **Nexus Core** and ability sigils inside the dedicated **Nexus Creative Tab** (containing all 25 custom item/block entries).

| Default input | Action |
| :--- | :--- |
| **Right-Click** *(Nexus Core)* | Awaken into 600-HP Nexus Form or open the Control Menu |
| **Sneak + Right-Click** *(Nexus Core)* | Deactivate Nexus Form |
| **Right-Click** *(Sigils / Menu)* | Cast selected cosmic ability |
| **`V`** | Skip active awakening or finale cutscene |
| **`N`** | Toggle cutscenes On / Off |

## Configuration and limits

NEXUS separates gameplay authority and client presentation across two TOML files in `.minecraft/config/`:

| File | Responsibility |
| :--- | :--- |
| `config/nexus.toml` | Controls gameplay rules, ability damage, cooldowns, entity targeting, and terrain destruction |
| `config/nexus-client.toml` | Controls 3D VFX visual quality, dynamic camera movement, and screen shake |

### Default behavioral switches

| Configuration domain | Default | Meaning |
| :--- | :---: | :--- |
| **Terrain Destruction** (`nexus.toml`) | `Enabled` | Permanent crater excavation and beam terrain destruction |
| **Passive/Neutral Mob Damage** (`nexus.toml`) | `Enabled` | Abilities damage hostile, passive, and neutral mobs |
| **Recruited Ally Protection** (`nexus.toml`) | `Enabled` | Recruited and summoned allies ignore operator collateral damage |
| **Cutscenes & Camera Shake** (`nexus-client.toml`) | `Enabled` | Awakening/finale camera tracks and impact vibration |

## Building from source

Install a **Java 25 JDK** and point `JAVA_HOME` to it. This repository includes full Java source, assets, recipes, the Gradle wrapper, and automated Python build scripts.

**Standalone Build Route (Release Verified):**

```bash
git clone [https://github.com/MrBoss1017/NEXUS.git](https://github.com/MrBoss1017/NEXUS.git)
cd NEXUS
python scripts/build_standalone.py --bundle
