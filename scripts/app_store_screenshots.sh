#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source "$script_dir/lib/common.sh"

env_file="${APP_STORE_SCREENSHOTS_ENV_FILE:-$repo_root/.env}"
ios_localization_id="${APP_STORE_SCREENSHOTS_IOS_VERSION_LOCALIZATION_ID:-}"
macos_localization_id="${APP_STORE_SCREENSHOTS_MAC_VERSION_LOCALIZATION_ID:-}"
project_path="$repo_root/AnyTime.xcodeproj"
bundle_id="in.fourplex.anytime"
derived_data_path="$repo_root/build/app-store-screenshots/DerivedData"
output_root="$repo_root/screenshots"
iphone_output_path="$output_root/ios/iphone67"
ipad_output_path="$output_root/ios/ipad129"
desktop_path="$output_root/macos/desktop"
ios_runtime="${APP_STORE_SCREENSHOTS_IOS_RUNTIME:-}"
iphone_device_type="${APP_STORE_SCREENSHOTS_IPHONE_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-14-Pro-Max}"
ipad_device_type="${APP_STORE_SCREENSHOTS_IPAD_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPad-Pro-12-9-inch-6th-generation-8GB}"
iphone_simulator_name="${APP_STORE_SCREENSHOTS_IPHONE_NAME:-AnyTime App Store iPhone 6.7}"
ipad_simulator_name="${APP_STORE_SCREENSHOTS_IPAD_NAME:-AnyTime App Store iPad 12.9}"
reference_date="${APP_STORE_SCREENSHOTS_REFERENCE_DATE:-2026-03-03T05:01:00Z}"
search_text="${APP_STORE_SCREENSHOTS_SEARCH_TEXT:-Tokyo}"
app_path=""

configure_upload() {
  require_command asc
}

configure_capture() {
  require_command python3
  require_command xcodebuild
  require_command xcodegen
  require_command xcrun

  ios_runtime="$(resolve_ios_runtime)"

  mkdir -p "$iphone_output_path" "$ipad_output_path"
}

resolve_ios_runtime() {
  if [[ -n "$ios_runtime" ]]; then
    printf '%s\n' "$ios_runtime"
    return 0
  fi

  xcrun simctl list runtimes --json | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
ios_runtimes = []

for runtime in payload.get("runtimes", []):
    identifier = runtime.get("identifier", "")
    if identifier.startswith("com.apple.CoreSimulator.SimRuntime.iOS-") is False:
        continue
    if runtime.get("isAvailable") is not True:
        continue

    version = runtime.get("version", "")
    try:
        version_key = tuple(int(part) for part in version.split("."))
    except ValueError:
        continue

    ios_runtimes.append((version_key, identifier))

if not ios_runtimes:
    raise SystemExit("No available iOS simulator runtime found.")

ios_runtimes.sort()
print(ios_runtimes[-1][1])
'
}

simulator_udid() {
  local simulator_name="$1"

  xcrun simctl list devices --json | python3 -c '
import json
import sys

name = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
for runtimes in devices.values():
    for device in runtimes:
        if device["name"] == name:
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit(1)
' "$simulator_name"
}

ensure_simulator() {
  local simulator_name="$1"
  local device_type="$2"
  local udid

  if udid="$(simulator_udid "$simulator_name" 2>/dev/null)"; then
    printf '%s\n' "$udid"
    return 0
  fi

  xcrun simctl create "$simulator_name" "$device_type" "$ios_runtime"
}

boot_simulator() {
  local udid="$1"

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override \
    --time 9:41 \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100
}

build_app() {
  generate_xcode_project "$repo_root"

  rm -rf "$derived_data_path"
  mkdir -p "$iphone_output_path" "$ipad_output_path"

  log "Building AnyTime for Simulator"
  run_xcodebuild \
    -scheme AnyTime \
    -project "$project_path" \
    -configuration Debug \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$derived_data_path" \
    build

  app_path="$derived_data_path/Build/Products/Debug-iphonesimulator/AnyTime.app"
  if [[ ! -d "$app_path" ]]; then
    fail "Built app not found at $app_path"
  fi
}

configuration_hex() {
  python3 - <<'PY'
import binascii
import json

payload = {
    "favoriteTimeZoneIDs": ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"],
    "preferredCityNamesByTimeZoneID": {},
    "labelStyle": "city",
    "dateStyle": "weekdayAndTime",
    "usesLocationTimeZone": False,
    "automaticTimeZoneID": "UTC",
}
print(binascii.hexlify(json.dumps(payload, separators=(",", ":")).encode("utf-8")).decode("ascii"))
PY
}

seed_configuration() {
  local udid="$1"
  local data_hex

  data_hex="$(configuration_hex)"

  xcrun simctl spawn "$udid" defaults delete "$bundle_id" AnyTime.Configuration.v2 >/dev/null 2>&1 || true
  xcrun simctl spawn "$udid" defaults write "$bundle_id" AnyTime.Configuration.v2 -data "$data_hex"
}

install_app() {
  local udid="$1"

  xcrun simctl terminate "$udid" "$bundle_id" >/dev/null 2>&1 || true
  xcrun simctl uninstall "$udid" "$bundle_id" >/dev/null 2>&1 || true
  xcrun simctl install "$udid" "$app_path" >/dev/null
}

capture_scenario() {
  local udid="$1"
  local scenario="$2"
  local output_path="$3"
  local wait_seconds="$4"

  install_app "$udid"
  seed_configuration "$udid"

  if [[ "$scenario" == "search" ]]; then
    SIMCTL_CHILD_ANYTIME_SCREENSHOT_SCENARIO="$scenario" \
      SIMCTL_CHILD_ANYTIME_SCREENSHOT_REFERENCE_DATE="$reference_date" \
      SIMCTL_CHILD_ANYTIME_SCREENSHOT_SEARCH_TEXT="$search_text" \
      xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" >/dev/null
  else
    SIMCTL_CHILD_ANYTIME_SCREENSHOT_SCENARIO="$scenario" \
      SIMCTL_CHILD_ANYTIME_SCREENSHOT_REFERENCE_DATE="$reference_date" \
      xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" >/dev/null
  fi

  sleep "$wait_seconds"
  xcrun simctl io "$udid" screenshot "$output_path" >/dev/null
}

capture_ios_device_set() {
  local udid="$1"
  local output_path="$2"

  mkdir -p "$output_path"
  rm -f "$output_path"/*.png

  capture_scenario "$udid" home "$output_path/01-home.png" 2
  capture_scenario "$udid" reference-time "$output_path/02-reference-time.png" 2
  capture_scenario "$udid" search "$output_path/03-search.png" 2
  capture_scenario "$udid" settings "$output_path/04-settings.png" 2
}

require_screenshot_dir() {
  local path="$1"
  local label="$2"

  if [[ ! -d "$path" ]]; then
    fail "$label screenshots directory does not exist: $path"
  fi

  if ! find "$path" -maxdepth 1 -type f -name '*.png' | grep -q .; then
    fail "$label screenshots directory is empty: $path"
  fi
}

delete_display_type_screenshots() {
  local localization_id="$1"
  shift
  local -a display_types=("$@")
  local screenshot_id

  while IFS= read -r screenshot_id; do
    [[ -n "$screenshot_id" ]] || continue
    run_asc screenshots delete --id "$screenshot_id" --confirm >/dev/null
  done < <(
    run_asc screenshots list --version-localization "$localization_id" --output json | python3 - "${display_types[@]}" <<'PY'
import json
import sys

target_display_types = set(sys.argv[1:])
payload = json.load(sys.stdin)

for screenshot_set in payload.get("sets", []):
    display_type = screenshot_set.get("set", {}).get("attributes", {}).get("screenshotDisplayType")
    if display_type not in target_display_types:
        continue
    for screenshot in screenshot_set.get("screenshots", []):
        screenshot_id = screenshot.get("id")
        if screenshot_id:
            print(screenshot_id)
PY
  )
}

upload_ios() {
  local localization_id="${1:-$ios_localization_id}"

  require_non_empty "$localization_id" "APP_STORE_SCREENSHOTS_IOS_VERSION_LOCALIZATION_ID"
  require_screenshot_dir "$iphone_output_path" "iPhone"
  require_screenshot_dir "$ipad_output_path" "iPad"

  delete_display_type_screenshots "$localization_id" APP_IPHONE_67 APP_IPAD_PRO_3GEN_129

  log "Uploading iPhone screenshots..."
  run_asc screenshots upload \
    --version-localization "$localization_id" \
    --path "$iphone_output_path" \
    --device-type IPHONE_67

  log "Uploading iPad screenshots..."
  run_asc screenshots upload \
    --version-localization "$localization_id" \
    --path "$ipad_output_path" \
    --device-type IPAD_PRO_3GEN_129
}

upload_macos() {
  local localization_id="${1:-$macos_localization_id}"

  require_non_empty "$localization_id" "APP_STORE_SCREENSHOTS_MAC_VERSION_LOCALIZATION_ID"
  require_screenshot_dir "$desktop_path" "macOS"

  delete_display_type_screenshots "$localization_id" APP_DESKTOP

  log "Uploading macOS screenshots..."
  run_asc screenshots upload \
    --version-localization "$localization_id" \
    --path "$desktop_path" \
    --device-type APP_DESKTOP
}

usage() {
  printf '%s\n' "Usage: scripts/app_store_screenshots.sh [capture-ios|upload-ios [IOS_LOC_ID]|capture-upload-ios [IOS_LOC_ID]|upload-macos [MAC_LOC_ID]|upload [IOS_LOC_ID] [MAC_LOC_ID]]" >&2
}

load_env_file "$env_file"
normalize_auth_env
build_asc_args

case "${1:-upload}" in
  capture-ios)
    configure_capture
    iphone_udid="$(ensure_simulator "$iphone_simulator_name" "$iphone_device_type")"
    ipad_udid="$(ensure_simulator "$ipad_simulator_name" "$ipad_device_type")"
    build_app
    boot_simulator "$iphone_udid"
    boot_simulator "$ipad_udid"
    capture_ios_device_set "$iphone_udid" "$iphone_output_path"
    capture_ios_device_set "$ipad_udid" "$ipad_output_path"
    ;;
  upload-ios)
    configure_upload
    upload_ios "${2:-}"
    ;;
  capture-upload-ios)
    configure_capture
    configure_upload
    iphone_udid="$(ensure_simulator "$iphone_simulator_name" "$iphone_device_type")"
    ipad_udid="$(ensure_simulator "$ipad_simulator_name" "$ipad_device_type")"
    build_app
    boot_simulator "$iphone_udid"
    boot_simulator "$ipad_udid"
    capture_ios_device_set "$iphone_udid" "$iphone_output_path"
    capture_ios_device_set "$ipad_udid" "$ipad_output_path"
    upload_ios "${2:-}"
    ;;
  upload-macos)
    configure_upload
    upload_macos "${2:-}"
    ;;
  upload)
    configure_upload
    upload_ios "${2:-}"
    upload_macos "${3:-}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
