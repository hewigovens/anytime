set shell := ["zsh", "-cu"]

project := "AnyTime.xcodeproj"
scheme := "AnyTime"
package_path := "Packages/AnyTimeCore"
default_destination := "generic/platform=iOS Simulator"
macos_destination := "generic/platform=macOS"
testflight_script := "./scripts/testflight.sh"
screenshot_script := "./scripts/app_store_screenshots.sh"

default:
    @just --list

generate:
    command -v xcodegen >/dev/null || { echo "xcodegen is not installed"; exit 1; }
    xcodegen generate

open: generate
    open {{project}}

lint:
    command -v swiftlint >/dev/null || { echo "swiftlint is not installed"; exit 1; }
    swiftlint --config .swiftlint.yml

lint-fix:
    command -v swiftlint >/dev/null || { echo "swiftlint is not installed"; exit 1; }
    swiftlint --fix --config .swiftlint.yml

test:
    swift test --package-path {{package_path}}

build destination=default_destination:
    set -o pipefail
    xcodebuild -scheme {{scheme}} -project {{project}} -destination '{{destination}}' build | { command -v xcbeautify >/dev/null && xcbeautify || cat; }

build-macos destination=macos_destination:
    set -o pipefail
    xcodebuild -scheme AnyTimeMac -project {{project}} -destination '{{destination}}' build | { command -v xcbeautify >/dev/null && xcbeautify || cat; }

verify destination=default_destination:
    command -v xcodegen >/dev/null || { echo "xcodegen is not installed"; exit 1; }
    command -v swiftlint >/dev/null || { echo "swiftlint is not installed"; exit 1; }
    xcodegen generate
    swiftlint --config .swiftlint.yml
    swift test --package-path {{package_path}}
    set -o pipefail
    xcodebuild -scheme {{scheme}} -project {{project}} -destination '{{destination}}' build | { command -v xcbeautify >/dev/null && xcbeautify || cat; }

testflight-auth:
    {{testflight_script}} auth

testflight:
    {{testflight_script}} upload

testflight-macos:
    {{testflight_script}} upload-macos

app-store-screenshots ios_loc="" mac_loc="":
    {{screenshot_script}} upload {{ios_loc}} {{mac_loc}}

capture-app-store-screenshots-ios ios_loc="":
    {{screenshot_script}} capture-upload-ios {{ios_loc}}
