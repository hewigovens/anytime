# Contributing to AnyTime

## Requirements

- Xcode 26.x
- macOS with command line tools installed
- `xcodegen` to generate the local Xcode project
- `just` if you want the shortcut commands
- `xcbeautify` for readable `xcodebuild` output
- `swiftlint` only if you plan to run `just lint` or `just verify`
- `asc` only if you plan to run the TestFlight upload flow

## Getting started

```bash
just generate
just open
```

Or build from the command line:

```bash
just build
```

The generated `AnyTime.xcodeproj` is intentionally not committed. Recreate it from `project.yml` whenever needed.

## Project layout

- `App/` — SwiftUI app, screens, components, theming, clipboard parsing, and launch resources.
- `Packages/AnyTimeCore/` — Core models, timezone catalog/search, persistence, presentation formatting, and tests.
- `Design/` — App icon source concepts.
- `project.yml` — XcodeGen project definition.
- `justfile` — Common local commands.

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
just testflight
just testflight-macos
just app-store-screenshots
just capture-app-store-screenshots-ios
```

Notes:

- `just build` defaults to `generic/platform=iOS Simulator`
- `just build-macos` builds the native macOS app target
- `just verify` runs project generation, SwiftLint, package tests, and an app build
- `just lint` and `just verify` require `swiftlint`

Build a specific simulator destination:

```bash
just build "platform=iOS Simulator,name=iPhone 16"
```

## TestFlight uploads

The repo includes `just testflight` and `just testflight-macos` workflows built around [App-Store-Connect-CLI](https://github.com/rudrankriyam/App-Store-Connect-CLI).

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
- `.env` and `./.asc/` are ignored by git so API credentials stay local to your machine.

## App Store screenshots

```bash
just app-store-screenshots IOS_VERSION_LOCALIZATION_ID MAC_VERSION_LOCALIZATION_ID
just capture-app-store-screenshots-ios IOS_VERSION_LOCALIZATION_ID
```

## CI

GitHub Actions runs on every push and pull request. The workflow:

- checks out the repo
- installs `xcodegen`
- generates `AnyTime.xcodeproj`
- runs `swift test --package-path Packages/AnyTimeCore`
- builds the `AnyTime` scheme for `generic/platform=iOS Simulator`

Workflow file: `.github/workflows/ci.yml`
