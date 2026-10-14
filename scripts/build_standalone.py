#!/usr/bin/env python3
"""Verified no-remapping build for the unobfuscated Minecraft 26.3 game.

Requires Python 3.10+ and JDK 25. Downloads official pinned dependencies, compiles
with javac, embeds TOML dependencies, and creates both ZIP packages. Does not
redistribute any Minecraft or Java binaries. The standard Gradle/Loom build is
provided separately for ordinary development environments.
"""
from pathlib import Path
import argparse, concurrent.futures, hashlib, io, json, os, shutil, subprocess, sys, urllib.request, zipfile

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / '.standalone'
LIBS = CACHE / 'libraries'
BUILD = ROOT / 'build'
MC, LOADER, API, VERSION = '26.3', '0.19.5', '0.160.6+26.3', '1.0.0'

def fetch(url, path, sha1=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and (not sha1 or hashlib.sha1(path.read_bytes()).hexdigest() == sha1):
        return path
    temporary = path.with_suffix(path.suffix + '.part')
    with urllib.request.urlopen(url, timeout=90) as source, temporary.open('wb') as out:
        shutil.copyfileobj(source, out)
    if sha1 and hashlib.sha1(temporary.read_bytes()).hexdigest() != sha1:
        temporary.unlink()
        raise RuntimeError('Checksum mismatch for ' + path.name)
    temporary.replace(path)
    return path

def read_url(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return json.load(response)

def dependencies():
    manifest = read_url('https://piston-meta.mojang.com/mc/game/version_manifest_v2.json')
    version = next(v for v in manifest['versions'] if v['id'] == MC)
    meta_file = fetch(version['url'], CACHE / 'minecraft.json', version['sha1'])
    meta = json.loads(meta_file.read_text())
    server = meta['downloads']['server']
    bundle = fetch(server['url'], CACHE / 'server-bundle.jar', server['sha1'])
    with zipfile.ZipFile(bundle) as archive:
        for name in archive.namelist():
            if name.startswith('META-INF/versions/') and name.endswith('.jar'):
                (CACHE / 'minecraft.jar').write_bytes(archive.read(name))
            elif name.startswith('META-INF/libraries/') and name.endswith('.jar'):
                LIBS.mkdir(parents=True, exist_ok=True)
                (LIBS / Path(name).name).write_bytes(archive.read(name))
    api = fetch(f'https://maven.fabricmc.net/net/fabricmc/fabric-api/fabric-api/{API}/fabric-api-{API}.jar', CACHE / 'fabric-api.jar')
    with zipfile.ZipFile(api) as archive:
        for name in archive.namelist():
            if name.endswith('.jar'):
                (LIBS / Path(name).name).write_bytes(archive.read(name))
    profile = read_url(f'https://meta.fabricmc.net/v2/versions/loader/{MC}/{LOADER}/profile/json')
    downloads = []
    for lib in profile['libraries']:
        group, artifact, version = lib['name'].split(':')
        name = f'{artifact}-{version}.jar'
        downloads.append((lib['url'] + group.replace('.', '/') + f'/{artifact}/{version}/{name}', LIBS / name))
    downloads += [
        ('https://maven.fabricmc.net/net/fabricmc/fabric-loader/' + LOADER + '/fabric-loader-' + LOADER + '.jar', LIBS / f'fabric-loader-{LOADER}.jar'),
        ('https://repo.maven.apache.org/maven2/org/tomlj/tomlj/1.1.1/tomlj-1.1.1.jar', LIBS / 'tomlj-1.1.1.jar'),
        ('https://repo.maven.apache.org/maven2/org/antlr/antlr4-runtime/4.11.1/antlr4-runtime-4.11.1.jar', LIBS / 'antlr4-runtime-4.11.1.jar'),
        ('https://repo.maven.apache.org/maven2/org/junit/platform/junit-platform-console-standalone/1.13.4/junit-platform-console-standalone-1.13.4.jar', LIBS / 'junit-console.jar'),
    ]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(lambda job: fetch(*job), downloads))

def executable(name):
    name += '.exe' if os.name == 'nt' else ''
    home = os.environ.get('JAVA_HOME')
    result = str(Path(home) / 'bin' / name) if home else shutil.which(name)
    if not result:
        raise RuntimeError('Install JDK 25 and set JAVA_HOME, then rerun.')
    return result

def run(args):
    subprocess.run(args, cwd=ROOT, check=True)

def compile_and_test():
    javac = executable('javac')
    version = subprocess.check_output([javac, '-version'], text=True, stderr=subprocess.STDOUT)
    if int(version.split()[1].split('.')[0]) < 25:
        raise RuntimeError('JDK 25 or newer is required; detected ' + version.strip())
    classes = BUILD / 'classes/java/main'
    tests = BUILD / 'classes/java/test'
    for directory in (classes, tests):
        if directory.exists(): shutil.rmtree(directory)
        directory.mkdir(parents=True)
    classpath = os.pathsep.join([str(CACHE / 'minecraft.jar')] + [str(p) for p in sorted(LIBS.glob('*.jar'))])
    def compile_tree(source, target, cp):
        paths = sorted((ROOT / source).rglob('*.java'))
        args = ['--release', '25', '-proc:none', '-encoding', 'UTF-8', '-cp', cp, '-d', str(target)] + [str(p) for p in paths]
        # A javac response file avoids the Windows command-line length limit.
        argfile = BUILD / ('javac-' + target.name + '.args')
        argfile.write_text('\n'.join('"' + a.replace('\\', '\\\\').replace('"', '\\"') + '"' for a in args), encoding='utf-8')
        run([javac, '@' + str(argfile)])
    compile_tree('src/main/java', classes, classpath)
    compile_tree('src/test/java', tests, classpath + os.pathsep + str(classes))
    runtime_cp = os.pathsep.join([str(classes), str(tests), str(ROOT / 'src/main/resources'), str(CACHE / 'minecraft.jar'), str(LIBS / '*')])
    run([executable('java'), '-cp', runtime_cp, 'org.junit.platform.console.ConsoleLauncher', 'execute', '--select-class', 'com.mrboss.nexus.NexusLogicTest', '--disable-banner'])
    return classes

def package_jar(classes):
    output = BUILD / 'libs' / f'nexus-{VERSION}.jar'
    output.parent.mkdir(parents=True, exist_ok=True)
    metadata = json.loads((ROOT / 'src/main/resources/fabric.mod.json').read_text().replace('${version}', VERSION))
    embedded = ['tomlj-1.1.1.jar', 'antlr4-runtime-4.11.1.jar']
    metadata['jars'] = [{'file': 'META-INF/jars/' + name} for name in embedded]
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for directory in [classes, ROOT / 'src/main/resources']:
            for path in sorted(directory.rglob('*')):
                if path.is_file() and path.name != 'fabric.mod.json':
                    archive.write(path, path.relative_to(directory))
        archive.writestr('fabric.mod.json', json.dumps(metadata, indent=2))
        for name in embedded:
            # Loom's include() similarly supplies metadata for non-mod libraries.
            buffer = io.BytesIO()
            with zipfile.ZipFile(LIBS / name) as original, zipfile.ZipFile(buffer, 'w', zipfile.ZIP_DEFLATED) as nested:
                for entry in original.infolist(): nested.writestr(entry, original.read(entry.filename))
                if 'fabric.mod.json' not in original.namelist():
                    lib_id, lib_version = ('org_tomlj_tomlj', '1.1.1') if name.startswith('tomlj') else ('org_antlr_antlr4_runtime', '4.11.1')
                    nested.writestr('fabric.mod.json', json.dumps({'schemaVersion':1, 'id':lib_id, 'version':lib_version, 'name':name, 'custom':{'fabric-loom:generated':True}}))
            archive.writestr('META-INF/jars/' + name, buffer.getvalue())
        for name in ['LICENSE', 'THIRD_PARTY_NOTICES.md']:
            if (ROOT / name).exists(): archive.write(ROOT / name, name)
        for path in sorted((ROOT / 'licenses').glob('*')):
            if path.is_file(): archive.write(path, 'META-INF/licenses/' + path.name)
    return output

def bundle(jar):
    output = BUILD / 'packages'
    output.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output / 'Nexus-26.3-Mod-Package.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.write(jar, 'mods/' + jar.name)
        archive.write(CACHE / 'fabric-api.jar', f'mods/fabric-api-{API}.jar')
        archive.write(ROOT / 'README.md', 'README.md')
        archive.write(ROOT / 'LICENSE', 'LICENSE')
        archive.write(ROOT / 'THIRD_PARTY_NOTICES.md', 'THIRD_PARTY_NOTICES.md')
        for directory in ['docs', 'licenses']:
            for path in sorted((ROOT / directory).rglob('*')):
                if path.is_file(): archive.write(path, path.relative_to(ROOT))
        for path in sorted(ROOT.rglob('*')):
            rel = path.relative_to(ROOT)
            if any(part in {'build', '.standalone', '.gradle', '.git', 'run', '__pycache__'} for part in rel.parts): continue
            if path.is_file(): archive.write(path, 'source/' + str(rel).replace('\\', '/'))
    with zipfile.ZipFile(output / 'Nexus-26.3-Config-Package.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.write(ROOT / 'src/main/resources/nexus-default.toml', 'config/nexus.toml')
        archive.write(ROOT / 'docs/CONFIG.md', 'CONFIG.md')
    print('Created both archives in', output)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', action='store_true', help='Also create both requested ZIP packages.')
    parser.add_argument('--offline', action='store_true', help='Use already downloaded dependencies.')
    args = parser.parse_args()
    if not args.offline: dependencies()
    classes = compile_and_test()
    jar = package_jar(classes)
    print('Built', jar)
    if args.bundle: bundle(jar)

if __name__ == '__main__':
    try: main()
    except Exception as exc:
        print('Build failed:', exc, file=sys.stderr)
        sys.exit(1)
