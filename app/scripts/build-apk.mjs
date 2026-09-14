#!/usr/bin/env node
/**
 * Builds an installable Android APK on this machine, no Expo account needed.
 *
 *   npm run build:apk        release APK — JS bundled in, runs on its own
 *   npm run build:apk:dev    debug APK — the dev client; needs `npm start`
 *                            running on the same Wi-Fi for live reload
 *
 * If Gradle fails with "ninja: error: manifest 'build.ninja' still dirty",
 * a file-sync tool (OneDrive) is touching files mid-build: retry, or keep the
 * project in a folder OneDrive does not sync.
 *
 * Both need the Android SDK (ANDROID_HOME) and a JDK 17, which `expo run:android`
 * also needs. The native project is generated with `expo prebuild` on first use.
 *
 * The release build is signed with the debug keystore that prebuild sets up,
 * which is fine for installing on your own phones and for sharing with the
 * farm. Generate a real keystore before any store upload.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, copyFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const variant = process.argv.includes('--dev') ? 'debug' : 'release';
const isWindows = process.platform === 'win32';

function run(command, args, cwd) {
  console.log(`\n> ${command} ${args.join(' ')}\n`);
  const result = spawnSync(isWindows ? `"${command}"` : command, args, { cwd, stdio: 'inherit', shell: isWindows });
  if (result.status !== 0) {
    console.error(`\n${command} failed with exit code ${result.status}`);
    process.exit(result.status ?? 1);
  }
}

if (!existsSync(join(root, 'android'))) {
  run('npx', ['expo', 'prebuild', '--platform', 'android', '--no-install'], root);
}

const androidDir = join(root, 'android');
const gradle = join(androidDir, isWindows ? 'gradlew.bat' : 'gradlew');
const task = variant === 'release' ? 'assembleRelease' : 'assembleDebug';
// 64-bit ARM covers every phone since 2016; x86_64 covers the emulator. Skipping
// the 32-bit ABIs halves the C++ compile, which is most of the build time.
// Pass --all-abis to build everything.
const abis = process.argv.includes('--all-abis') ? null : 'arm64-v8a,x86_64';
run(gradle, [task, ...(abis ? [`-PreactNativeArchitectures=${abis}`] : [])], androidDir);

const built = join(root, 'android', 'app', 'build', 'outputs', 'apk', variant, `app-${variant}.apk`);
if (!existsSync(built)) {
  console.error(`Expected an APK at ${built} but none was produced.`);
  process.exit(1);
}

const outDir = join(root, 'dist');
mkdirSync(outDir, { recursive: true });
const target = join(outDir, `qualihive-${variant}.apk`);
copyFileSync(built, target);

console.log(`
APK ready: ${target}

Install it on a phone plugged in with USB debugging on:
  adb install -r "${target}"
or copy the file to the phone and open it from the Files app.
${variant === 'debug' ? '\nThis is the dev client: run `npm start` on this PC and open the app on the same Wi-Fi.' : ''}`);
