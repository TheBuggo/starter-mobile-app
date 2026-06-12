#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Run the Flutter app on an iPhone Simulator.

Usage:
  scripts/run_ios_simulator.sh [flutter run args...]

Environment:
  IOS_SIMULATOR_NAME      iPhone simulator name to boot. Defaults to iPhone 15 Pro.
  IOS_SIMULATOR_ID        Exact simulator UDID to boot. Overrides IOS_SIMULATOR_NAME.
  DART_DEFINE_FILE        Dart define file to pass to Flutter. Defaults to .env.
  FLUTTER_DEVICE_TIMEOUT  Optional seconds Flutter should wait for the simulator.
USAGE
  exit 0
fi

simulator_name="${IOS_SIMULATOR_NAME:-iPhone 15 Pro}"
simulator_id="${IOS_SIMULATOR_ID:-}"
dart_define_file="${DART_DEFINE_FILE:-.env}"
device_timeout="${FLUTTER_DEVICE_TIMEOUT:-}"

find_simulator_id_by_name() {
  local line name udid

  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"

    if [[ "$line" =~ ^(.+)[[:space:]]\(([0-9A-Fa-f-]{36})\)[[:space:]]\(.+\)[[:space:]]*$ ]]; then
      name="${BASH_REMATCH[1]}"
      udid="${BASH_REMATCH[2]}"

      if [[ "$name" == "$simulator_name" ]]; then
        echo "$udid"
        return 0
      fi
    fi
  done < <(xcrun simctl list devices available)
}

if [[ -z "$simulator_id" ]]; then
  simulator_id="$(find_simulator_id_by_name)"
fi

if [[ -z "$simulator_id" ]]; then
  echo "iPhone Simulator '$simulator_name' was not found." >&2
  echo "Available simulators:" >&2
  xcrun simctl list devices available >&2
  exit 1
fi

if [[ -n "$dart_define_file" && ! -f "$dart_define_file" ]]; then
  echo "Dart define file '$dart_define_file' was not found." >&2
  echo "Create it from .env.example or run with DART_DEFINE_FILE= to skip it." >&2
  exit 1
fi

echo "Starting iPhone Simulator '$simulator_name' ($simulator_id)..."
xcrun simctl boot "$simulator_id" >/dev/null 2>&1 || true
open -a Simulator --args -CurrentDeviceUDID "$simulator_id"
xcrun simctl bootstatus "$simulator_id" -b >/dev/null

run_args=(-d "$simulator_id")

if [[ -n "$device_timeout" ]]; then
  run_args+=("--device-timeout=$device_timeout")
fi

if [[ -n "$dart_define_file" ]]; then
  run_args+=("--dart-define-from-file=$dart_define_file")
fi

echo "Running Flutter on iPhone Simulator '$simulator_name'..."
exec flutter run "${run_args[@]}" "$@"
