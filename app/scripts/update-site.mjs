#!/usr/bin/env node
/** Copies the release APK and its version to the download site after a successful build. */
import { copyFileSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const appDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const siteDir = resolve(appDir, '..', 'site');

try {
  const { expo } = JSON.parse(readFileSync(join(appDir, 'app.json'), 'utf8'));
  const version = expo?.version;
  if (typeof version !== 'string' || !/^\d+\.\d+\.\d+(?:-[\da-z.-]+)?(?:\+[\da-z.-]+)?$/i.test(version)) {
    throw new Error('Set a valid version in app/app.json before updating the site.');
  }

  const apk = join(appDir, 'dist', 'qualihive-release.apk');
  const apkInfo = statSync(apk);
  if (!apkInfo.isFile() || apkInfo.size === 0) {
    throw new Error('The release APK is empty or invalid. Run npm run build:apk again.');
  }

  const page = join(siteDir, 'index.html');
  const html = readFileSync(page, 'utf8');
  const versionPill = /(<span\b[^>]*\bid=["']version["'][^>]*>)[^<]*(<\/span>)/g;
  if ([...html.matchAll(versionPill)].length !== 1) {
    throw new Error('Expected exactly one version span with id="version" in site/index.html.');
  }
  const updated = html.replace(versionPill, (_, opening, closing) => `${opening}v${version}${closing}`);

  // Validate the inputs before replacing either of the site's files.
  copyFileSync(apk, join(siteDir, 'qualihive-release.apk'));
  writeFileSync(page, updated);

  console.log(`Updated site/qualihive-release.apk (${(apkInfo.size / 1048576).toFixed(1)} MB).`);
  console.log(`Updated site/index.html to v${version}.`);
  console.log('Commit and push the site changes to publish them on Render.');
} catch (error) {
  console.error(`Site update failed: ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
}
