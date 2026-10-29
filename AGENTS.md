# AnyTime Agent Notes

## Project Shape

- `App/` contains the SwiftUI app, platform views, and app support code.
- `Packages/AnyTimeCore/` owns timezone search, persistence, presentation logic, and core tests. Keep platform adapters thin.
- `project.yml` is the source of truth for targets, deployment versions, and release numbers. `AnyTime.xcodeproj` is generated and must not be committed.
- `README.md` introduces the app; `CONTRIBUTING.md` documents setup and detailed workflows.

## Workflow

- Use `just` commands for routine local work.
- Use `jj` when `.jj/` exists; otherwise use Git. Use `h/` for new branch names.
- `main` requires pull requests. Update a relevant existing PR instead of pushing directly to `main`.
- Run `just generate` after editing `project.yml`.
- Prefer `just build` for iOS and `just build-macos` for macOS.
- `xcodebuild` output in repo commands should stay piped through `xcbeautify`.
- Keep comments focused on non-obvious reasons and constraints.

## Verification

- Core logic: run `just test` or `swift test --package-path Packages/AnyTimeCore`.
- Shared SwiftUI or platform bridges: build both targets with `just build` and `just build-macos`; inspect affected layouts in the running app.
- Broad validation: run `just verify`. Report existing lint failures separately from regressions; do not claim full verification if the command fails.
- Focused lint: `swiftlint lint --no-cache --config .swiftlint.yml <changed Swift files>` avoids unrelated generated-source and cache issues.
- Shell changes: run `bash -n` on affected scripts and exercise the changed behavior.
- Documentation and screenshot changes: check the diff, links, image loading, and rendered README. App builds are unnecessary unless app code also changed.

## Screenshots and README Assets

- Native App Store captures live under ignored `screenshots/`; tracked README assets live under `docs/images/`.
- Preserve native dimensions for App Store uploads. Optimize documentation copies as WebP and retain useful transparency.
- For README captures of rounded displays, use `simctl io ... screenshot --mask alpha`; `--mask black` creates visible black corners. Check the result on light and dark backgrounds.
- Capture real app UI and preserve its text, controls, and proportions. Keep documentation derivatives separate from submission originals.
- Only one Duo display renders at a time. Match framebuffer ports by dimensions, capture the active display, and preserve the other posture's captures.
- Stage captures and validate decoded pixels before replacing good files. A valid PNG can still contain a blank inactive display.
- See `CONTRIBUTING.md` for Duo dimensions, capture commands, and posture requirements.
- Verify install commands against their actual package or tap before adding them to the README. A tap's existence does not establish that an AnyTime cask exists.

## Release Tooling

- Shared shell helpers live in `scripts/lib/common.sh`.
- TestFlight automation lives in `scripts/testflight.sh`.
- App Store screenshot capture/upload lives in `scripts/app_store_screenshots.sh`.
- App Store Connect credentials live in local `.env` and `.asc/`; do not commit either or print credentials and private review contact details.
- Use `just testflight` for iOS uploads and `just testflight-macos` for macOS uploads.
- Set release versions and build numbers in `project.yml`. Check existing App Store Connect builds for collisions before choosing an unused build number, then regenerate the project.
- After upload, verify the exact platform, version, build number, and `VALID` processing state. Reuse processed builds when preparing review submissions.
- Carry forward existing listing metadata and review contacts, then update release notes for each platform's actual changes. Verify screenshot delivery has completed.
- Run submission readiness checks for all target platforms before submitting either one: shared app-info state changes can make CLI selection ambiguous after the first submission. For iOS validation, pass the exported IPA so iPad screenshot requirements are checked.
- Submission and public release are separate actions. When asked only to submit for review, use manual release and confirm the resulting review-queue state.
- Uploads, submissions, public releases, and replacement of live store screenshots require user authorization covering that action.
