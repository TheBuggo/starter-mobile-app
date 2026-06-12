#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

usage() {
  cat <<'USAGE'
Run the Starter App on one or more Flutter targets.

Usage:
  scripts/run_app.sh <target> [args...]

Targets:
  macos       Run the macOS desktop app.
  chrome      Run the web app in Chrome.
  android     Run the Pixel Android emulator.
  ios         Run the iPhone Simulator.
  phones      Run Android and iPhone in separate Terminal windows.
  desktop     Run macOS and Chrome in separate Terminal windows.
  all         Run Android, iPhone, macOS, and Chrome in separate Terminal windows.
  supabase-start
              Start local Supabase services.
  supabase-stop
              Stop local Supabase services and keep local data.
  nuke        Stop local Supabase services and delete local data volumes.

Environment:
  DART_DEFINE_FILE      Dart define file to pass to Flutter. Defaults to .env.
  ANDROID_EMULATOR_ID   Android emulator id. Defaults to Pixel_10_Pro_Fold.
  IOS_SIMULATOR_NAME    iPhone simulator name. Defaults to iPhone 15 Pro.
USAGE
}

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

target="$1"
shift

dart_define_file="${DART_DEFINE_FILE:-.env}"

flutter_run_args() {
  local device_id="$1"
  shift

  local run_args=(-d "$device_id")

  if [[ -n "$dart_define_file" ]]; then
    if [[ ! -f "$dart_define_file" ]]; then
      echo "Dart define file '$dart_define_file' was not found." >&2
      echo "Create it from .env.example or run with DART_DEFINE_FILE= to skip it." >&2
      exit 1
    fi
    run_args+=("--dart-define-from-file=$dart_define_file")
  fi

  flutter run "${run_args[@]}" "$@"
}

run_single_target() {
  local single_target="$1"
  shift

  case "$single_target" in
    macos|mac)
      flutter_run_args macos "$@"
      ;;
    chrome|web)
      flutter_run_args chrome "$@"
      ;;
    android|pixel)
      "$script_dir/run_android_emulator.sh" "$@"
      ;;
    ios|iphone)
      "$script_dir/run_ios_simulator.sh" "$@"
      ;;
    supabase-start)
      "$script_dir/supabase_local.sh" start "$@"
      ;;
    supabase-stop)
      "$script_dir/supabase_local.sh" stop "$@"
      ;;
    nuke|supabase-nuke)
      "$script_dir/supabase_local.sh" nuke "$@"
      ;;
    *)
      echo "Unknown target '$single_target'." >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
}

expanded_targets() {
  case "$target" in
    phones|mobile|both)
      printf '%s\n' android ios
      ;;
    desktop)
      printf '%s\n' macos chrome
      ;;
    all)
      printf '%s\n' android ios macos chrome
      ;;
    macos|mac|chrome|web|android|pixel|ios|iphone|supabase-start|supabase-stop|nuke|supabase-nuke)
      printf '%s\n' "$target"
      ;;
    *)
      echo "Unknown target '$target'." >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
}

shell_quote() {
  local value="${1//\'/\'\\\'\'}"
  printf "'%s'" "$value"
}

applescript_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

env_prefix() {
  local names=(
    PATH
    DART_DEFINE_FILE
    ANDROID_EMULATOR_ID
    ANDROID_HOME
    ANDROID_SDK_ROOT
    FLUTTER_DEVICE_TIMEOUT
    IOS_SIMULATOR_ID
    IOS_SIMULATOR_NAME
  )

  local name
  for name in "${names[@]}"; do
    if [[ "${!name+x}" == "x" ]]; then
      printf '%s=%s ' "$name" "$(shell_quote "${!name}")"
    fi
  done
}

open_target_in_terminal() {
  local single_target="$1"
  shift

  local command
  command="cd $(shell_quote "$project_dir") && $(env_prefix)$(shell_quote "$script_dir/run_app.sh") $(shell_quote "$single_target")"

  local arg
  for arg in "$@"; do
    command+=" $(shell_quote "$arg")"
  done

  command+="; run_app_status=\$?; echo; echo Target $(shell_quote "$single_target") exited with status \$run_app_status.; echo Press Return to close this window.; read run_app_exit_prompt; exit \$run_app_status"

  if [[ "${RUN_APP_DRY_RUN:-}" == "1" ]]; then
    echo "$command"
    return
  fi

  local escaped_command
  escaped_command="$(applescript_quote "$command")"

  osascript <<OSA
tell application "Terminal"
  activate
  do script "$escaped_command"
end tell
OSA
}

targets=()
while IFS= read -r expanded_target; do
  targets+=("$expanded_target")
done < <(expanded_targets)

if [[ "${#targets[@]}" -eq 1 ]]; then
  run_single_target "${targets[0]}" "$@"
  exit $?
fi

if [[ "$(uname -s)" != "Darwin" || ! -x /usr/bin/osascript ]]; then
  echo "Grouped targets open separate Terminal windows and currently require macOS." >&2
  exit 1
fi

for single_target in "${targets[@]}"; do
  open_target_in_terminal "$single_target" "$@"
done

echo "Started targets: ${targets[*]}"
