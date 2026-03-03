# AnyTime

AnyTime is a modern SwiftUI rewrite of the original timezone calculator app.

It keeps the original "timezone calculator" idea, but the codebase is now built around SwiftUI, Swift Package Manager, XcodeGen, and a small local core package for search, persistence, and clock math.

## Highlights

- SwiftUI app lifecycle and views
- Local Swift package at `Packages/AnyTimeCore` for app logic and tests
- Search by city, region, abbreviation, and UTC offset
- Smart paste that can extract date and timezone hints from the clipboard
- Drag reordering, swipe actions, quick `+/-1h` and `+/-1d` controls
- Dark mode support
- Generated Xcode project via `project.yml`
- GitHub Actions CI for test + simulator build

## Requirements

- Xcode 26.x
- macOS with command line tools installed
- `xcodegen` to generate the local Xcode project
- `just` if you want the shortcut commands
- `xcbeautify` for readable `xcodebuild` output in local commands and upload scripts
- `swiftlint` only if you plan to run `just lint` or `just verify`
- `asc` only if you plan to run the TestFlight upload flow

The app targets deploy to iOS 17.0+ and macOS 14.0+.

## Project layout

- `App/`
  SwiftUI app, screens, components, theming, clipboard parsing, and launch resources.
- `Packages/AnyTimeCore/`
  Core models, timezone catalog/search, persistence, presentation formatting, and tests.
- `Design/`
  App icon source concepts.
- `project.yml`
  XcodeGen project definition.
- `justfile`
  Common local commands.

## Getting started

Generate the local Xcode project:

```bash
just generate
```

Open it in Xcode:

```bash
just open
```

Or build from the command line:

```bash
just build
```

The generated `AnyTime.xcodeproj` is intentionally not committed. Recreate it from `project.yml` whenever needed.

## Common commands

```bash
just generate
just open
just test
just build
just build-macos
just lint
just lint-fix
just verify
just testflight-auth
just testflight
just testflight-macos
just app-store-screenshots
just capture-app-store-screenshots-ios
```

Notes:

- `just build` defaults to `generic/platform=iOS Simulator`
- `just build-macos` builds the native macOS app target
- `just build`, `just build-macos`, `just verify`, and the TestFlight archive/export steps pipe `xcodebuild` through `xcbeautify` when available
- `just verify` runs project generation, SwiftLint, package tests, and an app build
- `just lint` and `just verify` require `swiftlint`
- `just testflight` archives a Release iOS build, exports an IPA, and uploads it with `asc`
- `just testflight-macos` archives a Release macOS build, exports a PKG, and uploads it with `asc`
- `just app-store-screenshots IOS_LOC_ID MAC_LOC_ID` uploads local App Store screenshot directories with `asc`
- `just capture-app-store-screenshots-ios IOS_LOC_ID` rebuilds the iOS simulator app, captures the standard App Store scenarios, and uploads them

Build a specific simulator destination:

```bash
just build "platform=iOS Simulator,name=iPhone 16"
```

## TestFlight uploads

The repo includes `just testflight` and `just testflight-macos` workflows built around [App-Store-Connect-CLI](https://github.com/rudrankriyam/App-Store-Connect-CLI) for App Store Connect / TestFlight automation.

One-time setup:

1. Install `asc` if it is not already available.
2. Install `xcbeautify` if it is not already available.
3. Copy `.env.example` to `.env`.
4. Fill in `ASC_APP_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and `APP_STORE_CONNECT_KEY_PATH`.
   If macOS lives under a separate App Store Connect record, also set `ASC_MAC_APP_ID`.
5. Run `just testflight-auth` to write a repo-local `./.asc/config.json`.

Then upload with:

```bash
just testflight
just testflight-macos
```

Notes:

- `just testflight` regenerates `AnyTime.xcodeproj`, archives the `AnyTime` scheme for `generic/platform=iOS`, exports an IPA to `build/testflight/ios/export/`, and uploads it with `asc`.
- `just testflight-macos` regenerates `AnyTime.xcodeproj`, archives the `AnyTimeMac` scheme for `generic/platform=macOS`, exports a PKG to `build/testflight/macos/export/`, uploads the PKG with Apple `altool`, and then uses `asc` for TestFlight build lookup / distribution.
- `ASC_MAC_APP_ID` is optional. If you omit it, the macOS flow falls back to `ASC_APP_ID`.
- `TESTFLIGHT_MAC_GROUP` is optional. If you omit it, the macOS flow falls back to `TESTFLIGHT_GROUP`.
- If an iOS group is configured, the command switches to `asc publish testflight`, waits for processing, and adds the build to that beta group.
- If a macOS group is configured, the command uploads the PKG first, then publishes the processed `MAC_OS` build to that beta group.
- The macOS upload path currently requires the App Store Connect API key variables in `.env`, because `altool` uses them directly for package upload.
- If you omit the API key variables, the upload step can still use an existing `asc auth login` session, but `xcodebuild` signing must then be satisfied by your local Xcode account setup.
- `.env` and `./.asc/` are ignored by git so API credentials stay local to your machine.

## App Store screenshots

The repo also includes `scripts/app_store_screenshots.sh`, structured the same way as the release scripts under `scripts/`.

Upload existing local screenshots with:

```bash
just app-store-screenshots IOS_VERSION_LOCALIZATION_ID MAC_VERSION_LOCALIZATION_ID
```

Capture and upload the standard iOS App Store screenshot set with:

```bash
just capture-app-store-screenshots-ios IOS_VERSION_LOCALIZATION_ID
```

Notes:

- The script sources shared helpers from `scripts/lib/common.sh`.
- The iOS capture flow generates four screens for both iPhone and iPad: home, reference-time editor, search, and settings.
- It uploads iPhone screenshots from `screenshots/ios/iphone67/`.
- iPad screenshots are uploaded from `screenshots/ios/ipad129/`.
- macOS screenshots are uploaded from `screenshots/macos/desktop/`.
- You can also set `APP_STORE_SCREENSHOTS_IOS_VERSION_LOCALIZATION_ID` and `APP_STORE_SCREENSHOTS_MAC_VERSION_LOCALIZATION_ID` in `.env` and run the script without arguments.

## CI

GitHub Actions runs on every push and pull request. The workflow:

- checks out the repo
- installs `xcodegen`
- generates `AnyTime.xcodeproj`
- runs `swift test --package-path Packages/AnyTimeCore`
- builds the `AnyTime` scheme for `generic/platform=iOS Simulator`

Workflow file:

- `.github/workflows/ci.yml`

## Notes on smart paste

The clipboard parser can resolve:

- dates and times from freeform text
- explicit timezone IDs such as `Asia/Tokyo`
- UTC/GMT offsets such as `UTC+9`
- city-style queries through the local search index
- additional city resolution through geocoding

On supported iOS 26 devices, the app can also use Apple's local Foundation Models APIs as a best-effort hinting layer.
