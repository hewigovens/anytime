# AnyTime Agent Notes

## Workflow

- Use `just` commands for routine local work.
- Run `just generate` after editing `project.yml`.
- Prefer `just build` for iOS and `just build-macos` for macOS.
- `xcodebuild` output in repo commands should stay piped through `xcbeautify`.

## Verification

- Core logic changes: run `swift test --package-path Packages/AnyTimeCore` or `just test`.
- macOS UI changes: run `xcodebuild -scheme AnyTimeMac -project AnyTime.xcodeproj -destination 'generic/platform=macOS' build`.
- Broad validation: run `just verify`.

## Project Shape

- `App/` contains the SwiftUI app, platform views, and app support code.
- `Packages/AnyTimeCore/` contains timezone search, persistence, presentation logic, and tests.
- `AnyTime.xcodeproj` is generated and should not be committed.

## Release Tooling

- Shared shell helpers live in `scripts/lib/common.sh`.
- TestFlight automation lives in `scripts/testflight.sh`.
- App Store screenshot capture/upload lives in `scripts/app_store_screenshots.sh`.
- App Store Connect credentials live in local `.env` and `.asc/`; do not commit either.
- Use `just testflight` for iOS uploads and `just testflight-macos` for macOS uploads.
