# Qualihive

Companion app for the Arduino-based honey filtration machine with quality
assessment, built for Honey Ko Bee Farm.

**Download for Android:** the download page in [`site/`](site/), hosted as a static site on Render.

| Folder | What it is |
| --- | --- |
| [`app/`](app/) | The React Native (Expo) app — this is what gets built and shipped. See its [README](app/README.md). |
| [`site/`](site/) | The download page and the APK it serves, deployed as a static site on Render. |
| [`dart_copy/`](dart_copy/) | The original Flutter build, kept as the behavioural reference. Not maintained. |

## Publishing a new version

1. Bump `version` in [`app/app.json`](app/app.json).
2. Build the APK and copy it next to the download page:
   ```bash
   cd app && npm run build:apk
   cp dist/qualihive-release.apk ../site/qualihive-release.apk
   ```
3. Update the version pill (`id="version"`) in [`site/index.html`](site/index.html),
   then commit and push to `main`. Render redeploys `site/` and serves the new APK.

## One-time GitHub setup

- **Settings → Pages → Build and deployment → Source:** *GitHub Actions*.
- **Settings → Actions → General → Workflow permissions:** *Read and write*
  (so the release workflow can attach the APK).
