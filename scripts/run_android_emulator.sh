#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'USAGE'
Run the Flutter app on an Android phone emulator.

Usage:
  scripts/run_android_emulator.sh [flutter run args...]

Environment:
  ANDROID_EMULATOR_ID       Android emulator id to launch. Defaults to Pixel_10_Pro_Fold.
  ANDROID_SDK_ROOT/HOME     Android SDK location. Falls back to android/local.properties.
  DART_DEFINE_FILE          Dart define file to pass to Flutter. Defaults to .env.
  FLUTTER_DEVICE_TIMEOUT    Seconds to wait for the emulator. Defaults to 120.
USAGE
  exit 0
fi

emulator_id="${ANDROID_EMULATOR_ID:-Pixel_10_Pro_Fold}"
dart_define_file="${DART_DEFINE_FILE:-.env}"
device_timeout="${FLUTTER_DEVICE_TIMEOUT:-120}"

connected_android_emulator_id() {
  flutter devices 2>/dev/null | awk -F'•' '
    /android-/ && /emulator/ && id == "" {
      id = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
    }
    END {
      print id
    }
  '
}

android_sdk_dir() {
  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    echo "$ANDROID_SDK_ROOT"
    return
  fi

  if [[ -n "${ANDROID_HOME:-}" ]]; then
    echo "$ANDROID_HOME"
    return
  fi

  if [[ -f android/local.properties ]]; then
    awk -F= '$1 == "sdk.dir" { print $2; exit }' android/local.properties
  fi
}

launch_android_emulator() {
  local sdk_dir emulator_bin launch_label log_file

  sdk_dir="$(android_sdk_dir)"
  emulator_bin="${sdk_dir}/emulator/emulator"
  launch_label="starter-app.${emulator_id}.emulator"
  log_file="${TMPDIR:-/tmp}/starter-app-${emulator_id}-emulator.log"

  if [[ ! -x "$emulator_bin" ]]; then
    echo "Android SDK emulator binary was not found at '$emulator_bin'." >&2
    echo "Set ANDROID_SDK_ROOT or ANDROID_HOME to your Android SDK path." >&2
    exit 1
  fi

  if [[ "$(uname -s)" == "Darwin" ]] && command -v launchctl >/dev/null 2>&1; then
    # Remove keepalive jobs created by older versions of this helper.
    launchctl remove "$launch_label" >/dev/null 2>&1 || true
  fi

  nohup "$emulator_bin" -avd "$emulator_id" -netdelay none -netspeed full >"$log_file" 2>&1 &

  echo "Emulator log: $log_file"
}

if ! flutter emulators | awk -v wanted="$emulator_id" '
  $1 == wanted { found = 1 }
  END { exit found ? 0 : 1 }
'; then
  echo "Android emulator '$emulator_id' was not found." >&2
  echo "Available emulators:" >&2
  flutter emulators >&2
  exit 1
fi

device_id="$(connected_android_emulator_id)"

if [[ -z "$device_id" ]]; then
  echo "Starting Android emulator '$emulator_id'..."
  launch_android_emulator

  deadline=$((SECONDS + device_timeout))
  while [[ $SECONDS -lt $deadline ]]; do
    device_id="$(connected_android_emulator_id)"
    if [[ -n "$device_id" ]]; then
      break
    fi
    sleep 2
  done
fi

if [[ -z "$device_id" ]]; then
  echo "The Android emulator did not become available within ${device_timeout}s." >&2
  echo "Run 'flutter doctor' if the emulator window opened but Flutter cannot see it." >&2
  exit 1
fi

run_args=(-d "$device_id")

if [[ -n "$dart_define_file" ]]; then
  if [[ ! -f "$dart_define_file" ]]; then
    echo "Dart define file '$dart_define_file' was not found." >&2
    echo "Create it from .env.example or run with DART_DEFINE_FILE= to skip it." >&2
    exit 1
  fi
  run_args+=("--dart-define-from-file=$dart_define_file")
fi

echo "Running Flutter on Android device '$device_id'..."
exec flutter run "${run_args[@]}" "$@"
