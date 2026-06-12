#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

usage() {
  cat <<'USAGE'
Manage this starter app's local Supabase Docker services.

Usage:
  scripts/supabase_local.sh <command> [supabase args...]

Commands:
  start   Start local Supabase services.
  stop    Stop local Supabase services and keep local data.
  nuke    Stop local Supabase services and delete local data volumes.

Examples:
  scripts/supabase_local.sh start
  scripts/supabase_local.sh stop
  scripts/supabase_local.sh nuke
USAGE
}

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

command="$1"
shift

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI was not found on PATH." >&2
  echo "Install it before managing local Supabase services." >&2
  exit 1
fi

cd "$project_dir"

case "$command" in
  start)
    exec supabase start "$@"
    ;;
  stop)
    exec supabase stop "$@"
    ;;
  nuke|supabase-nuke)
    exec supabase stop --no-backup --yes "$@"
    ;;
  *)
    echo "Unknown Supabase command '$command'." >&2
    echo >&2
    usage >&2
    exit 1
    ;;
esac
