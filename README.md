# Telegram Music Player

[![CI](https://github.com/SalehTZ/telegram_music_player/actions/workflows/ci.yml/badge.svg)](https://github.com/SalehTZ/telegram_music_player/actions/workflows/ci.yml)

A Flutter music player for Android, built around the songs you collect on
Telegram. The goal is to gather those songs in one place, play them, and clean
them up: fix messy tags, find or replace album covers, and add lyrics.

> **Status:** early development. The UI from the design is in place and runs
> on demo data; reading your music library and real playback come next.

| Home | Songs | Drawer | Player |
| :---: | :---: | :---: | :---: |
| ![Home](docs/screenshots/home.png) | ![Songs](docs/screenshots/songs.png) | ![Drawer](docs/screenshots/drawer.png) | ![Player](docs/screenshots/player.png) |

## Features

Done:

- Home page with recently played songs, artists and favorites
- Songs list with format and duration
- Navigation drawer
- Now playing screen with controls, a seek bar and a lyrics preview
- Mini player floating over the home and songs pages

Planned:

- Playback with `just_audio` and `audio_service`
- Library from the `Music/Telegram` and `Download/Telegram` folders
- Tag editor for title, artist, album, cover and lyrics
- Album cover and lyrics search

## Where the songs come from

Telegram keeps its downloads in `Android/data/org.telegram.messenger/`, and
since Android 11 no other app can read that folder. Songs saved with
Telegram's **Save to Music** (`Music/Telegram`) or **Save to Downloads**
(`Download/Telegram`) are in shared storage, so the app can find them through
Android's media library.

## Getting started

You need [Flutter 3.16](https://docs.flutter.dev/release/archive) (the version
`pubspec.lock` was made with), the Android SDK and Java 17.

```sh
git clone https://github.com/SalehTZ/telegram_music_player.git
cd telegram_music_player
mkdir -p assets/audio   # listed in pubspec.yaml, but its contents are git-ignored
flutter pub get
flutter run
```

Run the checks that CI runs:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Project structure

```text
lib/
  main.dart                 entry point
  src/
    app.dart                MaterialApp, theme and the root bloc
    blocs/                  state management (flutter_bloc)
    constants/              colors, fonts, text styles, sizes and asset paths
    data/                   models and demo data
    presentation/
      screens/              main shell, home, songs and player
      widgets/              reusable widgets
    utils/                  small helpers
assets/
  fonts/                    Poppins
  icons/                    SVG icons exported from the design
  images/                   default album art
```

## CI and releases

GitHub Actions runs two workflows:

- **CI** (`.github/workflows/ci.yml`) runs on every push and pull request. It
  checks formatting, analyzes, runs the tests and builds a release APK. The APK
  is attached to the run as the `telegram-music-player-apk` artifact for 14
  days, so you can install any build from the Actions tab.
- **Release** (`.github/workflows/release.yml`) runs when you push a version
  tag. It builds the APK and publishes it as a GitHub release with
  generated release notes.

To publish a release:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The version name comes from the tag (`v0.1.0` becomes `0.1.0`) and the
version code from the workflow run number, so each release has a higher
version code than the last.

### Release signing

Android only installs an update if it's signed with the same key as the app
already on the phone. Without a key, the release workflow signs with a
temporary debug key, so each release has to be uninstalled before installing
the next. To sign with your own key:

1. Create a keystore once and keep it safe. If you lose it, users have to
   uninstall the app to get updates.

   ```sh
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

2. Add these repository secrets under **Settings → Secrets and variables →
   Actions**:

   | Secret | Value |
   | --- | --- |
   | `ANDROID_KEYSTORE_BASE64` | output of `base64 -w 0 upload-keystore.jks` (macOS: `base64 -i upload-keystore.jks`) |
   | `ANDROID_KEYSTORE_PASSWORD` | the keystore password |
   | `ANDROID_KEY_ALIAS` | `upload`, or the alias you chose |
   | `ANDROID_KEY_PASSWORD` | the key password |

To sign release builds on your own machine, create `android/key.properties`
(it's git-ignored):

```properties
storeFile=/absolute/path/to/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

## Screenshots

The screenshots above are rendered from the app with its demo data. To update
them after changing the UI:

```sh
flutter test test/screenshots_test.dart --dart-define=SCREENSHOT_DIR=docs/screenshots
```

## Credits

- The UI follows the project's Figma design.
- [Poppins](https://github.com/itfoundry/Poppins) font, licensed under the SIL
  Open Font License 1.1 (see `assets/fonts/Poppins-OFL.txt`).
