#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
project_path="$repo_root/AnyTime.xcodeproj"
configuration="Release"
export_options_plist="$repo_root/Config/TestFlightExportOptions.plist"
env_file="$repo_root/.env"
scheme=""
archive_destination=""
release_root=""
archive_path=""
export_path=""
derived_data_path=""
artifact_pattern=""
artifact_label=""
asc_platform=""
selected_app_id=""
selected_group=""
exported_artifact_path=""
bundle_id=""
build_version=""
build_number=""

log() {
  printf '%s\n' "$*"
}

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

load_env() {
  if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    source "$env_file"
  fi
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    fail "$command_name is not installed"
  fi
}

require_value() {
  local variable_name="$1"

  if [[ -z "${!variable_name:-}" ]]; then
    fail "$variable_name is required. Set it in .env or your shell."
  fi
}

require_non_empty() {
  local value="$1"
  local variable_name="$2"

  if [[ -z "$value" ]]; then
    fail "$variable_name is required. Set it in .env or your shell."
  fi
}

run_xcodebuild() {
  if command -v xcbeautify >/dev/null 2>&1; then
    xcodebuild "$@" | xcbeautify
  else
    xcodebuild "$@"
  fi
}

is_truthy() {
  case "$1" in
    1|[Tt][Rr][Uu][Ee]|[Yy][Ee][Ss]|[Oo][Nn]) return 0 ;;
    *) return 1 ;;
  esac
}

has_auth_key_values() {
  [[ -n "${APP_STORE_CONNECT_KEY_ID:-}${APP_STORE_CONNECT_ISSUER_ID:-}${APP_STORE_CONNECT_KEY_PATH:-}" ]]
}

expand_path() {
  local raw_path="$1"

  case "$raw_path" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~/"*)
      printf '%s/%s\n' "$HOME" "${raw_path#~/}"
      ;;
    *)
      printf '%s\n' "$raw_path"
      ;;
  esac
}

bootstrap_asc_auth() {
  local validation_mode="$1"
  local required="$2"
  local key_path
  local -a command_args

  if ! has_auth_key_values; then
    if [[ "$required" == "required" ]]; then
      fail "App Store Connect API key settings are required for this command."
    fi

    return 0
  fi

  require_command asc
  require_value APP_STORE_CONNECT_KEY_ID
  require_value APP_STORE_CONNECT_ISSUER_ID
  require_value APP_STORE_CONNECT_KEY_PATH

  key_path="$(expand_path "$APP_STORE_CONNECT_KEY_PATH")"
  if [[ ! -f "$key_path" ]]; then
    fail "APP_STORE_CONNECT_KEY_PATH does not exist: $key_path"
  fi

  command_args=(
    asc auth login
    --bypass-keychain
    --local
    --name "${APP_STORE_CONNECT_KEY_NAME:-AnyTime}"
    --key-id "$APP_STORE_CONNECT_KEY_ID"
    --issuer-id "$APP_STORE_CONNECT_ISSUER_ID"
    --private-key "$key_path"
  )

  if [[ "$validation_mode" == "validate" ]]; then
    command_args+=(--network)
  else
    command_args+=(--skip-validation)
  fi

  "${command_args[@]}"
}

build_auth_args() {
  local key_path

  XCODE_AUTH_ARGS=()

  if ! has_auth_key_values; then
    return 0
  fi

  require_value APP_STORE_CONNECT_KEY_ID
  require_value APP_STORE_CONNECT_ISSUER_ID
  require_value APP_STORE_CONNECT_KEY_PATH

  key_path="$(expand_path "$APP_STORE_CONNECT_KEY_PATH")"
  if [[ ! -f "$key_path" ]]; then
    fail "APP_STORE_CONNECT_KEY_PATH does not exist: $key_path"
  fi

  XCODE_AUTH_ARGS=(
    -authenticationKeyPath "$key_path"
    -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID"
    -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID"
  )
}

configure_target() {
  local target="$1"

  case "$target" in
    ios)
      scheme="AnyTime"
      archive_destination="generic/platform=iOS"
      release_root="$repo_root/build/testflight/ios"
      archive_path="$release_root/AnyTime.xcarchive"
      export_path="$release_root/export"
      derived_data_path="$release_root/DerivedData"
      artifact_pattern="*.ipa"
      artifact_label="IPA"
      asc_platform="IOS"
      selected_app_id="${ASC_APP_ID:-}"
      selected_group="${TESTFLIGHT_GROUP:-}"
      ;;
    macos)
      scheme="AnyTimeMac"
      archive_destination="generic/platform=macOS"
      release_root="$repo_root/build/testflight/macos"
      archive_path="$release_root/AnyTimeMac.xcarchive"
      export_path="$release_root/export"
      derived_data_path="$release_root/DerivedData"
      artifact_pattern="*.pkg"
      artifact_label="PKG"
      asc_platform="MAC_OS"
      selected_app_id="${ASC_MAC_APP_ID:-${ASC_APP_ID:-}}"
      selected_group="${TESTFLIGHT_MAC_GROUP:-${TESTFLIGHT_GROUP:-}}"
      ;;
    *)
      fail "Unknown target: $target"
      ;;
  esac
}

read_archive_build_metadata() {
  local app_bundle
  local info_plist

  app_bundle=$(find "$archive_path/Products/Applications" -maxdepth 1 -type d -name '*.app' -print -quit)
  if [[ -z "$app_bundle" ]]; then
    fail "No app bundle was archived in $archive_path"
  fi

  info_plist="$app_bundle/Contents/Info.plist"
  if [[ ! -f "$info_plist" ]]; then
    fail "Archived app is missing Info.plist: $info_plist"
  fi

  bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$info_plist")
  build_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info_plist")
  build_number=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$info_plist")
}

archive_build() {
  local artifact_path

  require_command xcodegen
  require_command xcodebuild
  build_auth_args

  cd "$repo_root"

  log "Generating Xcode project..."
  xcodegen generate

  mkdir -p "$release_root"
  rm -rf "$archive_path" "$export_path" "$derived_data_path"

  log "Archiving $scheme..."
  run_xcodebuild \
    -scheme "$scheme" \
    -project "$project_path" \
    -configuration "$configuration" \
    -destination "$archive_destination" \
    -archivePath "$archive_path" \
    -derivedDataPath "$derived_data_path" \
    -allowProvisioningUpdates \
    "${XCODE_AUTH_ARGS[@]}" \
    archive

  log "Exporting $artifact_label..."
  run_xcodebuild \
    -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_path" \
    -exportOptionsPlist "$export_options_plist" \
    -allowProvisioningUpdates \
    "${XCODE_AUTH_ARGS[@]}"

  artifact_path=$(find "$export_path" -maxdepth 1 -type f -name "$artifact_pattern" -print -quit)
  if [[ -z "$artifact_path" ]]; then
    fail "No $artifact_label was exported to $export_path"
  fi

  exported_artifact_path="$artifact_path"

  if [[ "$asc_platform" == "MAC_OS" ]]; then
    read_archive_build_metadata
  fi
}

upload_ios_build() {
  local ipa_path="$1"
  local output_format="${TESTFLIGHT_OUTPUT:-table}"
  local locale="${TESTFLIGHT_LOCALE:-en-US}"
  local -a upload_command

  require_command asc
  require_non_empty "$selected_app_id" "ASC_APP_ID"

  if [[ -n "$selected_group" ]]; then
    upload_command=(
      asc publish testflight
      --app "$selected_app_id"
      --ipa "$ipa_path"
      --platform "$asc_platform"
      --group "$selected_group"
      --wait
      --output "$output_format"
    )

    if [[ -n "${TESTFLIGHT_TEST_NOTES:-}" ]]; then
      upload_command+=(
        --test-notes "$TESTFLIGHT_TEST_NOTES"
        --locale "$locale"
      )
    fi

    if [[ -n "${TESTFLIGHT_TIMEOUT:-}" ]]; then
      upload_command+=(--timeout "$TESTFLIGHT_TIMEOUT")
    fi

    if is_truthy "${TESTFLIGHT_NOTIFY:-0}"; then
      upload_command+=(--notify)
    fi
  else
    upload_command=(
      asc builds upload
      --app "$selected_app_id"
      --ipa "$ipa_path"
      --platform "$asc_platform"
      --output "$output_format"
    )

    if [[ -n "${TESTFLIGHT_TEST_NOTES:-}" ]]; then
      upload_command+=(
        --wait
        --test-notes "$TESTFLIGHT_TEST_NOTES"
        --locale "$locale"
      )
    elif is_truthy "${TESTFLIGHT_WAIT:-0}"; then
      upload_command+=(--wait)
    fi
  fi

  log "Uploading $(basename "$ipa_path")..."
  "${upload_command[@]}"
}

upload_macos_build() {
  local pkg_path="$1"
  local output_format="${TESTFLIGHT_OUTPUT:-table}"
  local locale="${TESTFLIGHT_LOCALE:-en-US}"
  local -a publish_command

  require_command asc
  require_non_empty "$selected_app_id" "ASC_MAC_APP_ID or ASC_APP_ID"
  require_non_empty "$bundle_id" "CFBundleIdentifier"
  require_non_empty "$build_version" "CFBundleShortVersionString"
  require_non_empty "$build_number" "CFBundleVersion"

  upload_macos_pkg "$pkg_path"

  if [[ -n "$selected_group" ]]; then
    publish_command=(
      asc publish testflight
      --app "$selected_app_id"
      --build-number "$build_number"
      --version "$build_version"
      --platform "$asc_platform"
      --group "$selected_group"
      --wait
      --output "$output_format"
    )

    if [[ -n "${TESTFLIGHT_TEST_NOTES:-}" ]]; then
      publish_command+=(
        --test-notes "$TESTFLIGHT_TEST_NOTES"
        --locale "$locale"
      )
    fi

    if [[ -n "${TESTFLIGHT_TIMEOUT:-}" ]]; then
      publish_command+=(--timeout "$TESTFLIGHT_TIMEOUT")
    fi

    if is_truthy "${TESTFLIGHT_NOTIFY:-0}"; then
      publish_command+=(--notify)
    fi

    log "Publishing macOS build $build_version ($build_number) to TestFlight..."
    "${publish_command[@]}"
    return 0
  fi

  if [[ -n "${TESTFLIGHT_TEST_NOTES:-}" ]] || is_truthy "${TESTFLIGHT_WAIT:-0}"; then
    wait_for_build_processing "$output_format"
  fi

  if [[ -n "${TESTFLIGHT_TEST_NOTES:-}" ]]; then
    upsert_test_notes "$(find_build_id)" "$locale" "$TESTFLIGHT_TEST_NOTES" "$output_format"
  fi
}

upload_build() {
  local artifact_path="$1"

  case "$asc_platform" in
    IOS)
      upload_ios_build "$artifact_path"
      ;;
    MAC_OS)
      upload_macos_build "$artifact_path"
      ;;
    *)
      fail "Unsupported App Store Connect platform: $asc_platform"
      ;;
  esac
}

upload_macos_pkg() {
  local pkg_path="$1"
  local key_path
  local -a upload_command

  require_command xcrun
  require_value APP_STORE_CONNECT_KEY_ID
  require_value APP_STORE_CONNECT_ISSUER_ID
  require_value APP_STORE_CONNECT_KEY_PATH

  key_path="$(expand_path "$APP_STORE_CONNECT_KEY_PATH")"
  if [[ ! -f "$key_path" ]]; then
    fail "APP_STORE_CONNECT_KEY_PATH does not exist: $key_path"
  fi

  upload_command=(
    xcrun altool
    --upload-package "$pkg_path"
    --platform macos
    --apple-id "$selected_app_id"
    --bundle-id "$bundle_id"
    --bundle-version "$build_number"
    --bundle-short-version-string "$build_version"
    --api-key "$APP_STORE_CONNECT_KEY_ID"
    --api-issuer "$APP_STORE_CONNECT_ISSUER_ID"
    --p8-file-path "$key_path"
    --output-format json
  )

  log "Uploading $(basename "$pkg_path") with altool..."
  "${upload_command[@]}"
}

wait_for_build_processing() {
  local output_format="$1"
  local -a wait_command

  wait_command=(
    asc builds wait
    --app "$selected_app_id"
    --build-number "$build_number"
    --platform "$asc_platform"
    --output "$output_format"
  )

  if [[ -n "${TESTFLIGHT_TIMEOUT:-}" ]]; then
    wait_command+=(--timeout "$TESTFLIGHT_TIMEOUT")
  fi

  log "Waiting for macOS build $build_version ($build_number) to finish processing..."
  "${wait_command[@]}"
}

find_build_id() {
  asc builds find \
    --app "$selected_app_id" \
    --build-number "$build_number" \
    --platform "$asc_platform" \
    --output json | python3 -c 'import json, sys; print(json.load(sys.stdin)["data"]["id"])'
}

upsert_test_notes() {
  local build_id="$1"
  local locale="$2"
  local notes="$3"
  local output_format="$4"

  if asc builds test-notes update \
    --build "$build_id" \
    --locale "$locale" \
    --whats-new "$notes" \
    --output "$output_format" >/dev/null 2>&1; then
    log "Updated TestFlight notes for macOS build $build_version ($build_number)."
    return 0
  fi

  asc builds test-notes create \
    --build "$build_id" \
    --locale "$locale" \
    --whats-new "$notes" \
    --output "$output_format"
}

usage() {
  printf '%s\n' "Usage: scripts/testflight.sh [auth|upload|upload-ios|upload-macos]" >&2
}

load_env
cd "$repo_root"

case "${1:-upload}" in
  auth)
    bootstrap_asc_auth validate required
    ;;
  upload|upload-ios)
    configure_target ios
    bootstrap_asc_auth skip optional
    archive_build
    upload_build "$exported_artifact_path"
    ;;
  upload-macos)
    configure_target macos
    bootstrap_asc_auth skip optional
    archive_build
    upload_build "$exported_artifact_path"
    ;;
  *)
    usage
    exit 1
    ;;
esac
