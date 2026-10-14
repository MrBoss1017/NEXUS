<p align="center">
  <img width="3584" height="1184" alt="banner2" src="https://github.com/user-attachments/assets/1587fabb-eef8-4d3a-824b-aca73ab24ea3" />

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

[Get started](#installation) · [The arsenal](#the-arsenal) · [Cosmic escalation](#cosmic-escalation) · [Commands](#commands) · [Configuration](#server-configuration) · [Build & test](#building-from-source)

**[Download NEXUS v1.1.0](https://github.com/MrBoss1017/NEXUS/releases/tag/v1.1.0)**

</div>

---

**NEXUS: Cosmic Dominion** is an original Minecraft **26.3** Fabric mod adapted from the original Nexus Luau architecture, turning destructive cosmic flash arts, entity conversion, and orbital-grade terrain excavation into an authored, server-authoritative spectacle. Awaken the Nexus Core, command nineteen distinct attack abilities, command a vanguard of recruited and summoned allies, or authorize a 34-phase ultimate finale—then walk through the incandescent craters left behind.

The spectacle has teeth. Targeting, damage verification, cooldown tracking, ally recruitment matrices, infection vectors, NPC summoning AI, and voxel excavation belong strictly to the server. The client builds the custom animated 3D VFX, dynamic camera interpolation, layered GLSL post-processing shaders, particles, soundscape, and holographic HUD from that authoritative timeline. Cosmetic visual scale and physical terrain devastation are independently controlled, so operators can preview massive cosmic demonstrations without excavating server terrain.

This repository includes the complete source tree, custom 3D assets, reproducible asset pipelines, test fixtures, operator examples, and dated engineering logs. Implementation, automated verification, and visual approvals are distinguished in [Validation and limitations](#validation-and-limitations).

## What NEXUS brings to Minecraft

* **Nineteen distinct attack abilities:** Cast targeted flash arts, radiant lances, gravitational ruptures, and localized orbital strikes via individual ability sigils or the radial Nexus HUD.
* **A 34-phase ultimate finale:** A sequential, catastrophic celestial collapse combining custom animated 3D VFX, atmospheric darkening, and synchronized shockfronts.
* **Persistent terrain deformation:** Irregular crater basins, continuous trench carving, scorching of surface materials, and subterranean collapses saved natively by Minecraft.
* **600-HP Nexus Form:** Awaken into a celestial host with a server-authoritative 600-HP maximum health pool, automatic hostile-entity engagement, and custom status barriers.
* **Ally recruitment, infection, and summons:** Infect living targets to spawn loyal mirrors, recruit natural entities into an immune faction list, and command five summoned combat NPC archetypes.
* **Directed cinematography:** Authored camera tracking, FOV warping, letterboxing, and screen rumble during awakenings and finales. Players remain active in the world and can move during sequences.
* **Authored presentation:** Custom animated 3D geometry, procedural energy beams, flash materials, smoke clouds, and persistent ambient aftermaths.
* **Synthesized audio architecture:** Multi-stage phase cues, mechanical charge locks, beam descent layers, and distance-delayed detonations.
* **Presentation and accessibility controls:** LOW, MEDIUM, and ULTRA rendering budgets, particle density sliders, camera shake adjustments, reduced motion toggles, and photosensitive flash dampening.
* **Bounded server work:** Global candidate budgets per tick, impact job reservation, protected-region verification, loaded-only chunk access, and deferred terrain re-evaluation.

## The arsenal

### THE NEXUS CORE & AWAKENED FORM

**Ascend beyond baseline mortality.**

The Nexus Core is the focal anchor of the system. When used, the server registers the operator's transformation into the **600-HP Nexus Form**. Surrounding atmosphere compresses, applying continuous cosmic regeneration, layered resistance, and autonomous combat targeting[cite: 3, 23].

While awakened, the server scans a configurable radius for eligible combat targets. Hostile and neutral mobs are marked for automated energy discharges, while verified allies remain strictly protected. Operators can sneak-use the Core to safely collapse the state and return to baseline player conditions.

### COSMIC ATTACK SIGILS (19 VARIATIONS)

**Precision devastation, bound to sigils.**

Each ability sigil triggers a dedicated server-side calculation and client visual script:
* **Linear Flash Beams:** Layered energy pillars that punch straight through terrain, excavating continuous cylindrical paths and scorching exposed stone into obsidian, basalt, or blackstone.
* **Kinetic Impact Bursts:** Rapid atmospheric detonations that cast nearby entities outward while carving shallow, fractured craters.
* **Gravitational Convergences:** Violet anomalies that draw eligible mobs toward a central singularity before detonating with high pressure.

Projectiles and beam heads are synchronized visual representations of deterministic server schedules. Supported exposed block boundaries undergo scorched-material transformation.

### RECRUITMENT, INFECTION & THE FIVE SUMMONS

**Command an expanding cosmic vanguard.**

NEXUS decouples individual spellcasting from total field control:
* **Faction Recruitment:** Entities designated via the recruitment matrix receive a persistent server tag preventing friendly fire from all operator abilities.
* **Cellular Infection:** Targets afflicted with the infection vector yield mirrored copies under operator command.
* **Summoned NPC Archetypes:** Five specialized combat entities (Vanguard, Striker, Bastion, Voidweaver, and Sentinel) deploy autonomously with bespoke engagement behaviors.

### STANDARD reference values

Bundled defaults at multiplier 1 and nominal **20 TPS**. Range, radius, and depth are measured in blocks; operator configuration can override effective geometry.

| Ability / System | Target range | Main radius / depth | Timeline | Cooldown from authorization |
| :--- | :---: | :---: | :---: | :---: |
| **Nexus Awakening** | Self | 8 / 4 (Aura) | Persistent | Instant / Sneak-Toggle |
| **Cosmic Flash Lance** | 128 | 16 / 12 | 120 ticks · 6.0 s | 300 ticks · 15.0 s |
| **Gravitational Anomaly** | 112 | 14 / 16 | 160 ticks · 8.0 s | 360 ticks · 18.0 s |
| **Crater Impact Burst** | 96 | 20 / 14 | 180 ticks · 9.0 s | 420 ticks · 21.0 s |
| **34-Phase Ultimate Finale** | 256 | 64 / 48 | 680 ticks · 34.0 s | 2400 ticks · 120.0 s |

The client presentation may finish before background block excavation concludes. Cooldowns initiate at authorization and are not reset by sequence cancellation.

## Cosmic escalation

STANDARD profiles represent baseline survival/creative gameplay. TITANIC and APOCALYPSE configurations use independent validated profiles defined in `config/nexus/scales.json`.

| Weapon / Protocol | TITANIC radius / depth | TITANIC timeline | APOCALYPSE radius / depth | APOCALYPSE timeline |
| :--- | :---: | :---: | :---: | :---: |
| **Flash Lance Array** | 96 / 32 | 45 s | 320 / 64 | 120 s |
| **Gravitational Singularity** | 80 / 48 | 40 s | 280 / 112 | 90 s |
| **Ultimate Finale (34-Phase)** | 128 / 64 | 60 s | 500 / 96 | 180 s |

These values represent **profile dimensions**, not an unconditional guarantee that server policy permits that footprint. Public mode clips physical geometry; destructive Apocalypse is disabled by default.

Start with an inert visual preview while aiming at a loaded surface within normal range:

text
/nexus preview finale apocalypse
/nexus bounds finale apocalypse
/nexus cast finale apocalypse
/nexus confirm

---

## Requirements

| Component | Project target |
| :--- | :--- |
| **Minecraft** | `26.3 only` |
| **Java** | `Java 25 JDK` for development; `Java 25+` required by metadata |
| **Fabric Loader** | `0.19.5` pinned for development |
| **Fabric API** | `0.160.6+26.3` pinned; included in distribution |
| **Mod Menu** | `21.0.0`, optional and client-only |
| **Fabric Loom** | `1.18.3`, pinned build plugin |
| **Gradle** | `9.7.1`, supplied wrapper with distribution checksum |

---

## Installation

1. Create a **Minecraft 26.3 Fabric** instance using Java 25 and the dependencies listed above.
2. Download `nexus-1.1.0.jar` from the **NEXUS v1.1.0 release**.
3. Place `nexus-1.1.0.jar` and matching Fabric API in the instance's `mods/` directory. Install the same files on your dedicated server.
4. Optionally install Mod Menu 21.0.0 on the client.
5. Launch the game. Configuration files are automatically generated under `config/nexus/` on first initialization.

> **Notice:** Install the production JAR only. Development `-sources.jar` and verification archives must never be used in production. Dedicated servers do not require Mod Menu. Use a disposable world for initial destructive testing.

---

## Server configuration

| File | Responsibility |
| :--- | :--- |
| `config/nexus/server.toml` | Authorization rules, candidate budgets, colossal policy, timings |
| `config/nexus/scales.json` | Validated TITANIC and APOCALYPSE geometric profiles |
| `config/nexus/abilities.json` | Base damage values, projectile curves, and knockback forces |
| `config/nexus/summons.json` | AI attributes and combat profiles for the 5 NPC summons |
| `config/nexus/client.toml` | Local visual and audio presentation preferences |

---

## Building from source

Install a Java 25 JDK, verify `JAVA_HOME` points to the installation directory, and utilize the provided Gradle wrapper.

### Clone & Build Commands

| Shell | Command |
| :--- | :--- |
| **Bash** | `git clone https://github.com/MrBoss1017/NEXUS.git`<br>`cd NEXUS`<br>`./gradlew clean build` |
| **PowerShell** | `git clone https://github.com/MrBoss1017/NEXUS.git`<br>`Set-Location NEXUS`<br>`.\gradlew.bat clean build` |

Production binaries output to `build/libs/nexus-1.1.0.jar`.

### Local Test Environments

powershell
# Launch local client test instance
.\gradlew.bat runClient

# Launch dedicated server test instance
.\gradlew.bat runServer

# Unobfuscated Mappings
.\gradlew.bat genSources
.\gradlew.bat build

---

### 5. Reproducible Original Assets (Image 5)

markdown
## Reproducible original assets

The `tools/assets/` directory provides standalone generation scripts for synthesized audio waveforms and particle materials using mathematical oscillators and filtered noise.

| Step | Script / Command | Purpose |
| :---: | :--- | :--- |
| **1** | `python -m pip install numpy Pillow soundfile` | Install generation dependencies |
| **2** | `python -I tools/assets/generate_textures.py` | Generate procedural particle textures |
| **3** | `python -I tools/assets/generate_audio.py` | Synthesize cosmic audio beds & SFX |
| **4** | `python -I tools/assets/validate_audio.py` | Validate audio formats and channel

---

## Verification and limitations

Release `v1.1.0` passed strict automated test gates prior to release tagging:

### Measured Terrain Devastation

| Scale / Profile | Dimensions | Block Changes | Resolution State |
| :--- | :---: | :---: | :--- |
| **Standard Impact** | Radius 64 / Depth 24 | 224,613 | Verified across 100% loaded chunk passes |
| **Heavy Bombardment** | Radius 160 / Depth 48 | 2,223,268 | 73% initial load, completed deferred resolution |
| **Apocalypse Finale** | Radius 500 / Depth 96 | 8,539,690 | 7,014,686 main pass + 1,525,004 deferred resolution |

### Automated Acceptance Suite

| Test Suite | Score | Status |
| :--- | :---: | :---: |
| `unit` | **6 / 6** | Passed |
| `server` | **120 / 120** | Passed |
| `graphical-client` | **31 / 31** | Passed |

---

## Source map and contributing

| Path | Contents |
| :--- | :--- |
| `src/main/java/com/mrboss/nexus` | Server-authoritative engine, 34-phase handler, entities, items |
| `src/client/java/com/mrboss/nexus/client` | Client HUD, shaders, camera tracking, particle controllers |
| `src/verification/java/com/mrboss/nexus/verification` | Automated GameTest harnesses and server check suites |
| `src/main/resources` | Fabric metadata, block models, recipes, sound json |
| `src/client/resources` | Shaders, render pipelines, post-processing materials |
| `tools/assets` | Procedural texture synthesizers and audio generators |
| `scripts` | Build automation and artifact verification pipelines |
| `docs` | Architectural specifications, verification evidence, and benchmarks |

---

## License and credits
Copyright © 2026 MrBoss1017 and NEXUS contributors.

Original NEXUS code, generated assets, and project documentation are licensed under the GNU General Public License version 3 only (GPL-3.0-only). See LICENSE and NOTICE for full terms.

Gradle wrapper components, Minecraft assets, Fabric APIs, and build toolchains retain their respective licenses.

NEXUS is an independent project and is not an official Minecraft product or approved by Mojang or Microsoft.

NEXUS · COSMIC DOMINION


