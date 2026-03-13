#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source "$script_dir/lib/common.sh"

project_path="$repo_root/AnyTime.xcodeproj"
scheme="AnyTime"
bundle_id="in.fourplex.anytime"
device_id="${1:-}"
derived_data_path="${2:-$repo_root/build/run/DerivedData}"

main() {
  local app_path

  require_command xcodebuild
  require_command xcodegen
  require_command xcrun

  if [[ -z "$device_id" ]]; then
    fail "Device ID is required."
  fi

  open -a Simulator
  xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device_id" -b

  generate_xcode_project "$repo_root"

  rm -rf "$derived_data_path"
  run_xcodebuild \
    -scheme "$scheme" \
    -project "$project_path" \
    -destination "id=$device_id" \
    -derivedDataPath "$derived_data_path" \
    build

  app_path="$derived_data_path/Build/Products/Debug-iphonesimulator/AnyTime.app"
  if [[ ! -d "$app_path" ]]; then
    fail "Built app not found at $app_path"
  fi

  xcrun simctl install "$device_id" "$app_path"
  xcrun simctl terminate "$device_id" "$bundle_id" >/dev/null 2>&1 || true
  xcrun simctl launch "$device_id" "$bundle_id"
}

main "$@"
