# Third-party notices

The newly authored Nexus port is MIT-licensed. This does not replace the licenses of the components below or grant rights to the user-supplied Luau reference.

| Component | Included form | License / upstream |
|---|---|---|
| Fabric API 0.160.6+26.3 | Separate, unmodified JAR in the mod ZIP | Apache-2.0; [FabricMC/fabric](https://github.com/FabricMC/fabric); original license retained in its JAR |
| TomlJ 1.1.1 | Nested library in the Nexus JAR | Apache-2.0; [tomlj/tomlj](https://github.com/tomlj/tomlj) |
| ANTLR 4 runtime 4.11.1 | Nested library in the Nexus JAR | BSD-3-Clause; copyright 2012–2022 The ANTLR Project; [license](https://github.com/antlr/antlr4/blob/4.11.1/LICENSE.txt) |
| Gradle wrapper | Wrapper scripts and wrapper JAR in source | Apache-2.0; [Gradle](https://github.com/gradle/gradle) |

Full license texts are in `licenses/` in the source and package, and `META-INF/licenses/` in the Nexus JAR. Fabric API and the Gradle wrapper also retain their embedded license files. The standalone builder adds generated Fabric metadata to the nested TomlJ and ANTLR JARs so Fabric Loader can load them; library bytecode is unchanged.

The build downloads additional Minecraft, Fabric Loader, Loom, Gradle and JUnit dependencies as needed; their complete installations are not distributed here. Minecraft and Java binaries are not included. Vanilla models, textures and sounds are referenced by identifier from the installed game.

`reference/Nexus-original.luau` is the unchanged user-provided input, included for traceability. No license or authorship claim over that input is made.
