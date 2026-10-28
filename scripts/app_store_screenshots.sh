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
duo_output_path="$output_root/ios/duo"
desktop_path="$output_root/macos/desktop"
ios_runtime="${APP_STORE_SCREENSHOTS_IOS_RUNTIME:-}"
iphone_device_type="${APP_STORE_SCREENSHOTS_IPHONE_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-14-Pro-Max}"
ipad_device_type="${APP_STORE_SCREENSHOTS_IPAD_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPad-Pro-12-9-inch-6th-generation-8GB}"
duo_device_type="${APP_STORE_SCREENSHOTS_DUO_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-Duo}"
iphone_simulator_name="${APP_STORE_SCREENSHOTS_IPHONE_NAME:-AnyTime App Store iPhone 6.7}"
ipad_simulator_name="${APP_STORE_SCREENSHOTS_IPAD_NAME:-AnyTime App Store iPad 12.9}"
duo_simulator_name="${APP_STORE_SCREENSHOTS_DUO_NAME:-AnyTime App Store iPhone Duo}"
reference_date="${APP_STORE_SCREENSHOTS_REFERENCE_DATE:-2026-03-03T05:01:00Z}"
search_text="${APP_STORE_SCREENSHOTS_SEARCH_TEXT:-Tokyo}"
# The screenshot scenarios, in the order they are numbered on the App Store page.
screenshot_scenarios=("home" "reference-time" "search" "settings")
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

  mkdir -p "$iphone_output_path" "$ipad_output_path" "$duo_output_path"
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

# Launches the app for one screenshot scenario and waits for it to settle.
#
# Shared by every device set; callers capture the display afterwards because the
# iPhone Duo needs to pick a specific framebuffer.
launch_scenario() {
  local udid="$1"
  local scenario="$2"
  local wait_seconds="$3"

  install_app "$udid"
  seed_configuration "$udid"

  if [[ "$scenario" == "search" ]]; then
    SIMCTL_CHILD_ANYTIME_SCREENSHOT_SEARCH_TEXT="$search_text" \
      SIMCTL_CHILD_ANYTIME_SCREENSHOT_REFERENCE_DATE="$reference_date" \
      SIMCTL_CHILD_ANYTIME_SCREENSHOT_SCENARIO="$scenario" \
      xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" >/dev/null
  else
    SIMCTL_CHILD_ANYTIME_SCREENSHOT_REFERENCE_DATE="$reference_date" \
      SIMCTL_CHILD_ANYTIME_SCREENSHOT_SCENARIO="$scenario" \
      xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" >/dev/null
  fi

  sleep "$wait_seconds"
}

capture_scenario() {
  local udid="$1"
  local scenario="$2"
  local output_path="$3"
  local wait_seconds="$4"

  launch_scenario "$udid" "$scenario" "$wait_seconds"
  xcrun simctl io "$udid" screenshot "$output_path" >/dev/null
}

# Captures one scenario from a specific iPhone Duo display.
#
# Only one Duo display renders at a time, so a flat capture means the device is
# in the wrong posture; that frame is rejected rather than written as a blank.
capture_duo_scenario() {
  local udid="$1"
  local display_port="$2"
  local scenario="$3"
  local output_path="$4"
  local wait_seconds="$5"

  launch_scenario "$udid" "$scenario" "$wait_seconds"
  xcrun simctl io "$udid" screenshot \
    --display "$display_port" \
    --type png \
    --mask black \
    "$output_path" >/dev/null

  assert_screenshot_not_blank "$output_path"
}

capture_ios_device_set() {
  local udid="$1"
  local output_path="$2"
  local index=1
  local scenario

  mkdir -p "$output_path"
  rm -f "$output_path"/*.png

  for scenario in "${screenshot_scenarios[@]}"; do
    capture_scenario "$udid" "$scenario" \
      "$(printf '%s/%02d-%s.png' "$output_path" "$index" "$scenario")" 2
    index=$((index + 1))
  done
}

# Finds the port UUID of the framebuffer whose native mode matches a size.
#
# iPhone Duo exposes two internal displays, and their port UUIDs are assigned
# fresh on every boot, so the display is located by its pixel size instead.
duo_display_port() {
  local udid="$1"
  local expected_width="$2"
  local expected_height="$3"

  xcrun simctl io "$udid" enumerate 2>/dev/null | python3 -c '
import re
import sys

expected = (int(sys.argv[1]), int(sys.argv[2]))

for block in sys.stdin.read().split("Port:")[1:]:
    identifier = re.search(r"Port Identifier: (\S+)", block)
    if not identifier or "framebuffer.display" not in identifier.group(1):
        continue

    uuid = re.search(r"UUID: (\S+)", block)
    width = re.search(r"Default width: (\d+)", block)
    height = re.search(r"Default height: (\d+)", block)
    if not (uuid and width and height):
        continue

    if (int(width.group(1)), int(height.group(1))) == expected:
        print(uuid.group(1))
        raise SystemExit(0)

raise SystemExit(1)
' "$expected_width" "$expected_height"
}

# Fails when a screenshot is a single flat colour.
#
# A folded iPhone Duo display captures as solid black, which would otherwise be
# uploaded as a valid looking but empty App Store screenshot.
assert_screenshot_not_blank() {
  local path="$1"

  if png_is_flat_colour "$path"; then
    fail "$path is a single flat colour, which means the iPhone Duo display was not rendering. Check that the device is in the posture you expect."
  fi
}

capture_duo_device_set() {
  local udid="$1"
  local output_path="$2"
  local inner_port outer_port active_posture
  local display_port file_suffix first_number display_label other_posture

  mkdir -p "$output_path"

  inner_port="$(duo_display_port "$udid" 2007 2853 || true)"
  outer_port="$(duo_display_port "$udid" 1398 2034 || true)"

  if [[ -z "$outer_port" || -z "$inner_port" ]]; then
    fail "Could not find both iPhone Duo displays on $udid"
  fi

  # Only one display is live at a time: unfolding lights up the inner display and
  # blanks the outer one, and folding it does the reverse. Capture whichever one
  # is rendering so a run never overwrites the other posture's good captures.
  active_posture="$(duo_active_posture "$udid" "$inner_port" "$outer_port")"

  case "$active_posture" in
    folded)
      display_port="$outer_port"
      display_label="outer display, 1398x2034"
      other_posture="Unfold the device in Device Hub and re-run to capture the inner display"
      file_suffix=""
      first_number=1
      ;;
    unfolded)
      display_port="$inner_port"
      display_label="inner display, 2853x2007"
      other_posture="Fold the device in Device Hub and re-run to capture the outer display"
      file_suffix="-inner"
      first_number=5
      ;;
    *)
      fail "iPhone Duo reported neither display as active on $udid"
      ;;
  esac

  log "iPhone Duo is ${active_posture}: capturing ${display_label}"
  log "$other_posture"

  local scenario
  for scenario in "${screenshot_scenarios[@]}"; do
    local file_path
    file_path="$(printf '%s/%02d%s-%s.png' "$output_path" "$first_number" "$file_suffix" "$scenario")"
    capture_duo_scenario "$udid" "$display_port" "$scenario" "$file_path" 3
    first_number=$((first_number + 1))
  done
}

# Reports whether the device is currently "folded" or "unfolded".
#
# Both framebuffers exist in either posture, so the posture is inferred from
# which one is actually rendering: the active display has varied pixels while
# the inactive one captures as a single flat colour.
duo_active_posture() {
  local udid="$1"
  local inner_port="$2"
  local outer_port="$3"
  local probe_dir
  local probe_status=0

  probe_dir="$(mktemp -d)"
  trap 'rm -rf "$probe_dir"' RETURN

  xcrun simctl io "$udid" screenshot --display "$inner_port" --type png --mask black \
    "$probe_dir/inner.png" >/dev/null 2>&1 || probe_status=1
  xcrun simctl io "$udid" screenshot --display "$outer_port" --type png --mask black \
    "$probe_dir/outer.png" >/dev/null 2>&1 || probe_status=1

  if [[ "$probe_status" -ne 0 ]]; then
    printf '%s\n' "unknown"
    return 0
  fi

  if png_is_flat_colour "$probe_dir/outer.png" && ! png_is_flat_colour "$probe_dir/inner.png"; then
    printf '%s\n' "unfolded"
  elif png_is_flat_colour "$probe_dir/inner.png" && ! png_is_flat_colour "$probe_dir/outer.png"; then
    printf '%s\n' "folded"
  else
    printf '%s\n' "unknown"
  fi
}

# Succeeds when a PNG has the same pixels on every row but the first.
#
# Only the zlib stream is inspected: every scanline re-filters identically for a
# flat image, and identical filtered rows decode to identical rows, so the full
# filter reconstruction is unnecessary. A capture from a display that is not
# rendering fails this immediately.
#
# Handles the 8-bit truecolour and truecolour-alpha PNGs that `simctl` writes,
# and reports "not flat" for any other layout so callers fall back safely.
png_is_flat_colour() {
  local path="$1"

  python3 - "$path" <<'PY'
import struct
import sys
import zlib

path = sys.argv[1]

with open(path, "rb") as handle:
    data = handle.read()

if not data.startswith(b"\x89PNG\r\n\x1a\n"):
    raise SystemExit(1)

index = 8
header = None
compressed = bytearray()

while index < len(data):
    length, chunk_type = struct.unpack(">I4s", data[index:index + 8])
    body = data[index + 8:index + 8 + length]
    index += 12 + length

    if chunk_type == b"IHDR":
        header = struct.unpack(">IIBBBBB", body)
    elif chunk_type == b"IDAT":
        compressed.extend(body)
    elif chunk_type == b"IEND":
        break

if header is None:
    raise SystemExit(1)

width, height, bit_depth, color_type, _, _, interlace = header
if bit_depth != 8 or interlace != 0 or color_type not in (2, 6):
    raise SystemExit(1)

if height < 2:
    raise SystemExit(0)

channels = 4 if color_type == 6 else 3
scanline = 1 + (width * channels)
raw = zlib.decompress(bytes(compressed))

if len(raw) < scanline * height:
    raise SystemExit(1)

reference = raw[scanline:scanline * 2]
for row in range(2, height):
    start = scanline * row
    if raw[start:start + scanline] != reference:
        raise SystemExit(1)

raise SystemExit(0)
PY
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

# Fails when a directory still holds a flat-colour capture.
#
# Only one iPhone Duo display renders at a time, so a leftover capture from the
# other posture is a blank frame. Catching it here stops a blank screenshot from
# replacing a good one on the App Store.
require_rendered_screenshots() {
  local path="$1"
  local label="$2"
  local file
  local blanks=()

  while IFS= read -r -d '' file; do
    if png_is_flat_colour "$file"; then
      blanks+=("$file")
    fi
  done < <(find "$path" -maxdepth 1 -type f -name '*.png' -print0)

  if [[ ${#blanks[@]} -gt 0 ]]; then
    printf '%s\n' "$label has ${#blanks[@]} blank screenshot(s):" >&2
    printf '  %s\n' "${blanks[@]}" >&2
    fail "$label screenshots contain blank frames. Re-capture them in the matching device posture."
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

upload_duo() {
  local localization_id="${1:-$ios_localization_id}"

  require_non_empty "$localization_id" "APP_STORE_SCREENSHOTS_IOS_VERSION_LOCALIZATION_ID"
  require_screenshot_dir "$duo_output_path" "iPhone Duo"
  require_rendered_screenshots "$duo_output_path" "iPhone Duo"

  # APP_IPHONE_DUO accepts both displays, so the outer and inner captures share
  # one set: 1398x2034 (outer) and 2007x2853 (inner).
  delete_display_type_screenshots "$localization_id" APP_IPHONE_DUO

  log "Uploading iPhone Duo screenshots..."
  run_asc screenshots upload \
    --version-localization "$localization_id" \
    --path "$duo_output_path" \
    --device-type APP_IPHONE_DUO
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
  printf '%s\n' "Usage: scripts/app_store_screenshots.sh [capture-ios|upload-ios [IOS_LOC_ID]|capture-upload-ios [IOS_LOC_ID]|capture-duo|upload-duo [IOS_LOC_ID]|capture-upload-duo [IOS_LOC_ID]|upload-macos [MAC_LOC_ID]|upload [IOS_LOC_ID] [MAC_LOC_ID]]" >&2
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
  capture-duo)
    configure_capture
    duo_udid="$(ensure_simulator "$duo_simulator_name" "$duo_device_type")"
    build_app
    boot_simulator "$duo_udid"
    capture_duo_device_set "$duo_udid" "$duo_output_path"
    ;;
  upload-duo)
    configure_upload
    upload_duo "${2:-}"
    ;;
  capture-upload-duo)
    configure_capture
    configure_upload
    duo_udid="$(ensure_simulator "$duo_simulator_name" "$duo_device_type")"
    build_app
    boot_simulator "$duo_udid"
    capture_duo_device_set "$duo_udid" "$duo_output_path"
    upload_duo "${2:-}"
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
