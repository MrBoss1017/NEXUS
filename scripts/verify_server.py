#!/usr/bin/env python3
"""Run the optional Nexus integration mod in a disposable, loopback-only world.

First build with build_standalone.py. Requires JDK 25, Python 3.10+, and explicit
acceptance of Minecraft's EULA: python scripts/verify_server.py --accept-eula.
The test mod and its accelerated config are never included in release packages.
"""
import argparse, json, os, shutil, subprocess, tempfile, zipfile
from pathlib import Path
import build_standalone as build

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--accept-eula', action='store_true')
    args = parser.parse_args()
    if not args.accept_eula:
        parser.error('Read https://aka.ms/MinecraftEULA and pass --accept-eula to run a local test server.')
    classes = build.BUILD / 'verification-classes'
    classes.mkdir(parents=True, exist_ok=True)
    libraries = sorted(build.LIBS.glob('*.jar'))
    cp = os.pathsep.join(map(str, [build.BUILD / 'classes/java/main', build.CACHE / 'minecraft.jar', *libraries]))
    source = build.ROOT / 'src/verification/java/com/mrboss/nexus/verification/NexusVerification.java'
    subprocess.run([build.executable('javac'), '--release', '25', '-proc:none', '-cp', cp, '-d', str(classes), str(source)], check=True)
    run = Path(tempfile.mkdtemp(prefix='verification-', dir=build.BUILD))
    (run / 'mods').mkdir(); (run / 'config').mkdir()
    with zipfile.ZipFile(run / 'mods/nexus-verification.jar', 'w', zipfile.ZIP_DEFLATED) as jar:
        for path in classes.rglob('*.class'): jar.write(path, path.relative_to(classes))
        jar.writestr('fabric.mod.json', json.dumps({'schemaVersion': 1, 'id': 'nexus_verification', 'version': '1.0.0', 'environment': 'server', 'entrypoints': {'main': ['com.mrboss.nexus.verification.NexusVerification']}, 'depends': {'nexus': '*', 'fabric-api': '*'}}))
    shutil.copy2(build.BUILD / f'libs/nexus-{build.VERSION}.jar', run / 'mods')
    shutil.copy2(build.CACHE / 'fabric-api.jar', run / 'mods/fabric-api.jar')
    config = (build.ROOT / 'src/main/resources/nexus-default.toml').read_text()
    (run / 'config/nexus.toml').write_text(config.replace('phase_ticks = 360', 'phase_ticks = 20').replace('particles_per_tick = 384', 'particles_per_tick = 16'))
    (run / 'eula.txt').write_text('eula=true\n')
    (run / 'server.properties').write_text('''server-ip=127.0.0.1
server-port=25576
online-mode=false
white-list=true
level-name=verification-world
level-type=minecraft:flat
generator-settings={"biome":"minecraft:plains","layers":[{"block":"minecraft:bedrock","height":1},{"block":"minecraft:stone","height":2},{"block":"minecraft:grass_block","height":1}]}
generate-structures=false
view-distance=3
simulation-distance=3
spawn-protection=0
max-tick-time=0
pause-when-empty-seconds=0
initial-enabled-packs=vanilla
''')
    runtime_libs = [p for p in libraries if not p.name.startswith('fabric-') or p.name.startswith('fabric-loader-')]
    runtime_libs = [p for p in runtime_libs if 'junit' not in p.name]
    runtime_cp = os.pathsep.join(map(str, [build.CACHE / 'minecraft.jar', *runtime_libs]))
    command = [build.executable('java'), '-Xmx1400M', '-Djava.net.preferIPv4Stack=true', '-Dfabric.gameJarPath=' + str(build.CACHE / 'minecraft.jar'), '-cp', runtime_cp, 'net.fabricmc.loader.impl.launch.knot.KnotServer', 'nogui']
    print('Isolated verification world:', run, flush=True)
    with (run / 'server.log').open('w') as log:
        process = subprocess.Popen(command, cwd=run, stdin=subprocess.PIPE, stdout=log, stderr=subprocess.STDOUT, text=True)
        try: process.wait(timeout=180)
        except subprocess.TimeoutExpired:
            process.terminate()
            try: process.wait(timeout=10)
            except subprocess.TimeoutExpired: process.kill(); process.wait()
            raise RuntimeError('Verification timed out; inspect ' + str(run / 'server.log'))
    report = run / 'nexus-verification.txt'
    if not report.exists(): raise RuntimeError('Server did not finish verification; inspect ' + str(run / 'server.log'))
    result = report.read_text(); print(result)
    if process.returncode != 0 or 'VERIFICATION PASSED' not in result: raise RuntimeError('Integration verification failed')
    shutil.copy2(report, build.BUILD / 'nexus-verification.txt')

if __name__ == '__main__': main()
