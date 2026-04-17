# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpotiRide is a Garmin Connect IQ watch-app for Edge 530 that displays Spotify track info during cycling and provides playback control. Written in Monkey C, targeting Connect IQ SDK 3.3.0+.

## Build & Deploy

Build the .prg binary (requires Connect IQ SDK and developer key):
```bash
java -jar "<SDK_PATH>/bin/monkeybrains.jar" -o bin/SpotiRide.prg -f SpotiRide/monkey.jungle -y "<DEVELOPER_KEY_PATH>/developer_key.der" -d edge530 -r
```
- `<SDK_PATH>` — Connect IQ SDK directory, typically `~/.Garmin/ConnectIQ/Sdks/<version>` (Linux/Mac) or `%APPDATA%/Garmin/ConnectIQ/Sdks/<version>` (Windows)
- `<DEVELOPER_KEY_PATH>` — location of your developer key, generated via "Monkey C: Generate Developer Key" in VS Code

Deploy to device (USB):
```bash
cp bin/SpotiRide.prg "<GARMIN_DRIVE>/GARMIN/APPS/SpotiRide.prg"
```
- `<GARMIN_DRIVE>` — the drive letter/mount point where the Edge 530 appears when connected via USB

No test framework or linter exists for Monkey C. Testing is manual on the device or via the Connect IQ simulator.

## Architecture

**Global singletons** (`$.gTokenManager`, `$.gSpotifyApi`) are initialized in `SpotifyApp.mc:onStart()` and accessed throughout the app.

**Source files in `SpotiRide/source/`:**
- `SpotifyApp.mc` — AppBase entry point, lifecycle, and `onOAuthMessage()` callback for OAuth
- `SpotifyView.mc` — Main view with 2-page layout (page 1: Spotify + ride data, page 2: speed/sunset/temp). Runs a 1.5s poll timer that refreshes Spotify data at configurable intervals
- `SpotifyDelegate.mc` — Button handling (LAP=like, START=record, MENU=settings) and full menu system with `Menu2`
- `SpotifyApi.mc` — Spotify REST API calls via `Communications.makeWebRequest()`. Handles currently-playing, like/unlike, playback controls (play/pause/next/prev/shuffle/repeat)
- `TokenManager.mc` — OAuth token lifecycle: `startOAuth()` triggers phone login via `makeOAuthRequest()`, `exchangeCodeForTokens()` trades auth code for tokens, `refreshAccessToken()` handles automatic refresh. Tokens stored in `Application.Storage`
- `AboutView.mc` — Static about screen with QR code

**OAuth flow:** `startOAuth()` -> phone login -> `onOAuthMessage()` in SpotifyApp.mc receives code -> `exchangeCodeForTokens()` -> `onTokenResponse()` saves refresh token to Storage. The `isOAuthInProgress` and `isExchangingCode` flags prevent the poll timer from interfering with this flow.

**oauth-helper/index.html** — Standalone browser page for obtaining Spotify refresh tokens manually (alternative to device OAuth).

## Credential Management

Real Spotify credentials (Client ID, Secret, Refresh Token) are stored in `my_tokens.txt` (gitignored). Before building for the user, insert real values into `TokenManager.mc`. Before any git commit, restore placeholders (`TWOJ_CLIENT_ID`, `TWOJ_CLIENT_SECRET`, `TWOJ_REFRESH_TOKEN`). The memory file `feedback_build_deploy.md` has the full procedure.

## Key Constraints

- **Edge 530 screen:** 246x322 pixels, limited fonts (FONT_XTINY through FONT_NUMBER_THAI_HOT)
- **No HTTP DELETE** in Connect IQ — can't unlike tracks
- **All HTTP goes through phone** via Bluetooth — requires Garmin Connect Mobile running
- **Monkey C limitations:** no base64 built-in, no string interpolation, limited collections API, `Lang.Dictionary` and `Lang.Array` type checks required on API responses
- **`makeWebRequest` POST** with Dictionary body auto-encodes as URL form data — do NOT set Content-Type header manually (numeric constants like `REQUEST_CONTENT_TYPE_URL_ENCODED` are for `:responseType`, not headers)
- **Bilingual UI:** use `s(pl, en)` helper or `langPolish` flag; all user-facing strings need both versions
- **`Activity.getActivityInfo().currentSpeed`** only works during active recording — use GPS `Position.enableLocationEvents()` as fallback
