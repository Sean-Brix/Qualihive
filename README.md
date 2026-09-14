# Qualihive

Companion app for the Arduino-based honey filtration machine with quality
assessment, built for Honey Ko Bee Farm.

**Download for Android:** https://sean-brix.github.io/Qualihive/

| Folder | What it is |
| --- | --- |
| [`app/`](app/) | The React Native (Expo) app — this is what gets built and shipped. See its [README](app/README.md). |
| [`site/`](site/) | The download page, published to GitHub Pages by [`pages.yml`](.github/workflows/pages.yml). |
| [`dart_copy/`](dart_copy/) | The original Flutter build, kept as the behavioural reference. Not maintained. |

## Publishing a new version

1. Bump `version` in [`app/app.json`](app/app.json).
2. Tag and push:
   ```bash
   git tag v1.0.1
   git push origin main v1.0.1
   ```
3. [`release-apk.yml`](.github/workflows/release-apk.yml) builds the APK on
   GitHub's runners and attaches it to the `v1.0.1` release. The download page
   always points at the latest release, so nothing else needs to change.

To publish an APK built on your own machine instead:

```bash
cd app && npm run build:apk
gh release create v1.0.1 dist/qualihive-release.apk --title "Qualihive v1.0.1" --generate-notes
```

## One-time GitHub setup

- **Settings → Pages → Build and deployment → Source:** *GitHub Actions*.
- **Settings → Actions → General → Workflow permissions:** *Read and write*
  (so the release workflow can attach the APK).
