#!/usr/bin/env bash
#
# artifacts.sh – multi-folder backup & restore
#   Layout:  <BASE>/<TARGET>/<FOLDER>/
#   Quiet:   shows only a compact rsync summary
# ---------------------------------------------------------
#   © 2025 – free to use / adapt

set -euo pipefail
command -v rsync >/dev/null || { echo "Error: rsync is not installed." >&2; exit 1; }

###############################################################################
# Help
###############################################################################
usage() {
cat <<'EOF'
Usage
-----

  artifacts.sh push --target=<repo> --source=<list> [--base=<dir>] [--delete]
  artifacts.sh pull --target=<repo> --source=<list> [--base=<dir>]

Flags
-----

  --target   (required) Directory under BASE that groups the artifacts.
  --source   (required) Comma-separated list of folders.
  --base     Root artifact dir (default: $HOME/.artifacts).
  --delete   Passes --delete to rsync (push only).
  --help     Show this help and exit.

Examples
--------

  artifacts.sh push --target="repo" \
                    --source=".next,node_modules" \
                    --delete

  artifacts.sh pull --target="repo" \
                    --source=".next,node_modules"
EOF
}

###############################################################################
# Positional command
###############################################################################
[[ $# -eq 0 ]] && { usage; exit 1; }
case "$1" in
  --help|-h) usage; exit 0 ;;
  push|pull) OPERATION="$1"; shift ;;
  *) echo "Error: first argument must be 'push', 'pull', or --help'." >&2
     usage; exit 1 ;;
esac

###############################################################################
# Default values
###############################################################################
BASE_DIR="$HOME/.artifacts"
DELETE_FLAG=""
TARGET=""
SRC_LIST_RAW=""

###############################################################################
# Manual flag parser (exact match, no abbreviations)
###############################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)   TARGET="$2"        || true; shift 2 ;;
    --target=*) TARGET="${1#*=}";         shift   ;;
    --source)   SRC_LIST_RAW="$2"  || true; shift 2 ;;
    --source=*) SRC_LIST_RAW="${1#*=}";   shift   ;;
    --base)     BASE_DIR="$2"      || true; shift 2 ;;
    --base=*)   BASE_DIR="${1#*=}";       shift   ;;
    --delete)   DELETE_FLAG="--delete";   shift   ;;
    --help|-h)  usage; exit 0 ;;
    *) echo "Error: unknown argument '$1' — use '--help' to see all options." >&2
       exit 1 ;;
  esac
done

# Required checks
[[ -z "$TARGET"     ]] && { echo "Error: --target is required." >&2; usage; exit 1; }
[[ -z "$SRC_LIST_RAW" ]] && { echo "Error: --source is required." >&2; usage; exit 1; }

###############################################################################
# Helpers
###############################################################################
IFS=',' read -r -a SOURCES <<< "$(echo "$SRC_LIST_RAW" | sed 's/[, ]\+/,/g')"
RSYNC_OPTS="-ah --stats $DELETE_FLAG"
mkdir -p "$BASE_DIR"

summary () {                      # silent rsync, print 5 key lines
  local out
  if ! out=$(rsync $RSYNC_OPTS "$1" "$2" 2>&1); then
    echo "$out" >&2; return 1
  fi
  echo "$out" | grep -E \
      'Number of files:|Number of transferred files:|Total file size:|Total transferred file size:| sent | speedup is'
}

###############################################################################
# Main
###############################################################################
case "$OPERATION" in
  push)
    for SRC in "${SOURCES[@]}"; do
      SRC_PATH=$(realpath "$SRC") || { echo "Error: '$SRC' not found." >&2; exit 1; }
      [[ -d "$SRC_PATH" ]] || { echo "Error: '$SRC_PATH' is not a directory." >&2; exit 1; }
      DEST="$BASE_DIR/$TARGET/$(basename "$SRC_PATH")"
      mkdir -p "$DEST"
      echo "▶ Push:  $SRC_PATH/  ->  $DEST/"
      summary "${SRC_PATH%/}/" "${DEST}/"
    done
    ;;
  pull)
    for FOLDER in "${SOURCES[@]}"; do
      SRC_DIR="$BASE_DIR/$TARGET/$FOLDER"
      if [[ ! -d "$SRC_DIR" ]]; then
        echo "ℹ️  Notice: source '$SRC_DIR' does not exist — skipped."
        continue
      fi
      DEST="./$FOLDER"
      mkdir -p "$DEST"
      echo "▶ Pull:  $SRC_DIR/  ->  $DEST/"
      summary "${SRC_DIR}/" "${DEST%/}/"
    done
    ;;
esac

echo "✔️  Done."