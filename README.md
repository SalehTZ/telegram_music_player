<h1 align="center">Telegram Music Player</h1>

<p align="center">
  <b>All the music you saved on Telegram, in one player.</b><br>
  A free Android music player for the songs you collect on Telegram:<br>
  play them, fix their messy tags, find album covers and add lyrics.
</p>

<p align="center">
  <a href="https://github.com/SalehTZ/telegram_music_player/releases"><img alt="Download" src="https://img.shields.io/github/v/release/SalehTZ/telegram_music_player?label=download&style=for-the-badge&color=5947B2"></a>
  <a href="#support-telegram-music-player"><img alt="Donate" src="https://img.shields.io/badge/donate-%E2%99%A5-ff5c8a?style=for-the-badge"></a>
</p>

<p align="center">
  <a href="https://github.com/SalehTZ/telegram_music_player/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/SalehTZ/telegram_music_player?style=flat&logo=github&color=f8e444"></a>
  <a href="https://github.com/SalehTZ/telegram_music_player/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/SalehTZ/telegram_music_player/total?label=downloads&logo=github"></a>
  <a href="https://github.com/SalehTZ/telegram_music_player/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/SalehTZ/telegram_music_player/ci.yml?branch=main&label=CI&logo=githubactions&logoColor=white"></a>
</p>

<p align="center">
  <img src="docs/screenshots/home.png" width="200" alt="Home">
  <img src="docs/screenshots/songs.png" width="200" alt="Songs">
  <img src="docs/screenshots/drawer.png" width="200" alt="Drawer">
  <img src="docs/screenshots/player.png" width="200" alt="Player">
</p>

> **Status:** early development. The app's screens are in place and run on demo
> data; reading your music library and real playback come next.

---

## Why Telegram Music Player?

Telegram is where a lot of us find music: channels, groups, friends sending
songs. But those files end up scattered, with titles like `@SomeChannel - track 03`
and no cover art. This app gathers them in one place and cleans them up.

Done:

- **Home** with recently played songs, artists and favorites
- **Songs** list with format and duration
- **Now playing** screen with controls, a seek bar and a lyrics preview
- **Mini player** floating over your library

Coming next:

- Playback with `just_audio` and `audio_service`
- Your library from the `Music/Telegram` and `Download/Telegram` folders
- A tag editor for title, artist, album, cover and lyrics
- Album cover and lyrics search

## Download

Grab the latest build from **[Releases](https://github.com/SalehTZ/telegram_music_player/releases)**:

| Platform | File |
|---|---|
| Android | `telegram-music-player-android-arm64-v8a.apk` (most phones), `armeabi-v7a` for older ones, `x86_64` for emulators and Chromebooks |

If you installed **v0.1.0**, uninstall it before installing a newer version. It
was a preview signed with a temporary key, so Android won't update it.

<details>
<summary>Verify that an APK is really from us</summary>

Every official Android release is signed with the same key as
[Snag](https://github.com/SalehTZ/snag). Check it with `apksigner` (from the
Android SDK build-tools):

```bash
apksigner verify --print-certs telegram-music-player-android-*.apk
```

The `SHA-256` digest must be:

```
A5:35:0A:AA:8A:BC:94:6C:C8:68:36:B7:70:F6:61:70:D3:EF:C2:AE:7E:6C:15:B3:DD:0A:3C:E6:A6:AA:13:8D
```

If it doesn't match, don't install it. An APK signed with a different key also
can't update an existing install. Each release also lists the files' checksums
in `SHA256SUMS.txt`.
</details>

## Support Telegram Music Player

Telegram Music Player is free and always will be: no ads, no paywalls, no "pro"
version. If you like it, please consider chipping in. Donations pay for the
hours that go into building it and keep it free for everyone.

<a href="https://github.com/sponsors/SalehTZ"><img alt="GitHub Sponsors" src="https://img.shields.io/badge/GitHub%20Sponsors-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white"></a>

**Crypto**, listed cheapest network first. Send only on the network shown; coins
sent on a different network can be lost for good.

| Network | On exchanges, pick | Send | Address |
|---|---|---|---|
| **BNB Smart Chain** (lowest fees) | `BSC` / `BEP20` | BNB, USDT | `0xDc131f09a194957EAdD1c069765BF9e78013Ac8C` |
| **Tron** | `TRON` / `TRC20` | TRX, USDT | `TPmJbZpicJEaG9Vj5sMLBmKvzMnyn7Bkxt` |
| **Ethereum** | `ETH` / `ERC20` | ETH, USDT | `0xDc131f09a194957EAdD1c069765BF9e78013Ac8C` |
| **Bitcoin** | `BTC` (SegWit, address starts with `bc1`) | BTC | `bc1qahd3arfp90rpny73dp9unjhcdl32mmnkrln7uy` |

<details>
<summary>Which network should I use?</summary>

- **BNB Smart Chain (BSC, BEP20)**: Binance's network. The cheapest here, usually a few cents. Not the same as "BNB Beacon Chain" or "opBNB".
- **Tron (TRC20)**: the most widely supported network for USDT, especially on Iranian exchanges. Sending USDT costs around $1 unless your wallet has staked TRX.
- **Ethereum (ERC20)**: the original smart-contract network. Often cheap lately, but fees can jump when it's busy.
- **Bitcoin**: the original. Fees vary with network load, and it's slower than the others.

The BNB Smart Chain and Ethereum addresses are the same. That's normal: both networks use the same address format. Just make sure the network you pick matches the row you're copying from.
</details>

You can also help for free:
- ⭐ **Star the repo.** It helps other people find the app.
- 🐛 **[Report bugs](https://github.com/SalehTZ/telegram_music_player/issues)** and suggest features.
- 📥 **Try [Snag](https://github.com/SalehTZ/snag)**, my free video and audio downloader.

## Where the songs come from

Telegram keeps its downloads in `Android/data/org.telegram.messenger/`, and
since Android 11 no other app can read that folder. Songs saved with
Telegram's **Save to Music** (`Music/Telegram`) or **Save to Downloads**
(`Download/Telegram`) are in shared storage, so the app can find them through
Android's media library.

## Build it yourself

You need [Flutter 3.16](https://docs.flutter.dev/release/archive) (the version
`pubspec.lock` was made with), the Android SDK and Java 17.

```sh
git clone https://github.com/SalehTZ/telegram_music_player.git
cd telegram_music_player
mkdir -p assets/audio   # listed in pubspec.yaml, but its contents are git-ignored
flutter pub get
flutter run

# Release build, one APK per CPU type
flutter build apk --release --split-per-abi
```

Run the checks that CI runs:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

To update the screenshots after changing the UI:

```sh
flutter test test/screenshots_test.dart --dart-define=SCREENSHOT_DIR=docs/screenshots
```

### Project structure

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

## Releases

Two GitHub Actions workflows build the app:

- **CI** (`.github/workflows/ci.yml`) runs on every push and pull request: it
  checks formatting, analyzes, runs the tests and builds one APK per CPU type,
  which you can download from the run for 14 days.
- **Release** (`.github/workflows/release.yml`) runs when a version tag is
  pushed. It builds one APK per CPU type, checks that each one is signed with
  the release key above, and publishes them with `SHA256SUMS.txt` as a GitHub
  release.

To publish a release:

```sh
git tag v0.2.0
git push origin v0.2.0
```

The version name comes from the tag and the version code from the workflow run
number.

### Release signing

Releases are signed with the same key as Snag, using the same repository
secrets (**Settings → Secrets and variables → Actions**). Copy the values from
Snag's secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the keystore file, base64-encoded |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password (also used as the key password) |
| `ANDROID_KEY_ALIAS` | the key alias |

Without them, or with a different key, the release workflow fails instead of
publishing an APK that can't update existing installs.

To sign release builds on your own machine, create `android/key.properties`
(it's git-ignored):

```properties
storeFile=/absolute/path/to/release.jks
storePassword=...
keyPassword=...
keyAlias=...
```

Without that file, release builds use the debug key, which is fine for testing.

## Credits

- The UI follows the project's Figma design.
- [Poppins](https://github.com/itfoundry/Poppins) font, licensed under the SIL
  Open Font License 1.1 (see `assets/fonts/Poppins-OFL.txt`).
