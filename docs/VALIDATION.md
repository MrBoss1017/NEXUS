# Validation record

Validated on 2026-10-12 against the actual **Minecraft 26.3** dedicated-server classes with **Fabric Loader 0.19.5**, **Fabric API 0.160.6+26.3**, and **OpenJDK 25**.

## Completed checks

- All production Java sources compiled against the real, unobfuscated Minecraft/Fabric APIs using `javac --release 25`.
- **Three JUnit tests passed**: cast/recovery/global cooldown boundaries; invalid TOML types, NaN, bounds and UUID rejection; default values and per-ability overrides.
- The packaged Nexus JAR loaded on a real Fabric server, including its mixins and embedded TOML dependencies. The server loaded the mod's recipes, loot and tags without Nexus data-loading errors.
- A separate, opt-in integration mod completed **101 checks**. The full report is in `server-verification.txt`.
- The integration run built the creative tab and verified all 25 custom entries, activated a 600-HP boss, and checked healing interception and immediate scheduled callbacks.
- All 19 regular attacks accepted an initial cast, rejected an immediate repeated cast, executed without effect exceptions, and landed damage on test targets.
- The finale accepted a cast, rejected an immediate repeat, and executed all 34 phases without effect exceptions.
- Recruitment, infection assignment, friendly-fire protection, manual release, restored NoAI state, recruitment immunity, all five NPC variants, cancellation cleanup, scheduler cleanup and original max-health restoration passed.
- The effect budget stayed bounded throughout that run.

The test world used 25 durable target mobs, loopback networking, no connected players, a 200-tick-per-second rate, 20-tick finale phases and a reduced particle budget. Regular attack durations remained at default values. These settings accelerate state/geometry checks; they are **not** the release defaults. Tests create a disposable world and never connect to a user server.

## Build-route limitation

The standard Gradle project and wrapper are included. Gradle resolved the Fabric toolchain, but Loom initialization in the delivery environment failed when its platform check attempted to create a Unix-domain socket prohibited by that environment. A complete Gradle build was therefore **not verified** here.

The included release JAR was built using `scripts/build_standalone.py`, which downloads official pinned dependencies and compiles without remapping because Minecraft 26.3 is unobfuscated. That actual JAR was successfully loaded and exercised on the server. This is not a placeholder JAR or a promise of a later build.

## Remaining validation scope

No interactive graphical client, real-player multiplayer session, long-duration default-speed finale, compatibility matrix with other mods, or production load test was available. Particle appearance, sound mix, menu feel, player-specific stomp controls, and full-length encounter balance still need in-game playtesting. Passing the automated checks does not constitute that playtest.

## Reproduce

Use JDK 25 and Python 3.10+:

```sh
python scripts/build_standalone.py
python scripts/verify_server.py --accept-eula
```

Read the [Minecraft EULA](https://aka.ms/MinecraftEULA) before passing `--accept-eula`. The runner creates a new directory beneath `build/verification-*`, compiles a separate test mod, copies the release JAR, and starts a temporary server bound to 127.0.0.1. It writes `server.log` and `nexus-verification.txt`, stops the server on completion, and fails if verification does not pass. The integration mod is never included in release `mods/`.

For the Gradle JUnit route, use `./gradlew test`. For asset regeneration only, install Pillow and run `python scripts/generate_assets.py`; PNGs and JSON assets are already included, so this is unnecessary for a normal build.
