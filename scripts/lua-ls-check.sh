#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
log_dir="${LUALS_LOG_DIR:-$repo_root/build/luals}"
check_level="${LUALS_CHECKLEVEL:-Warning}"
lua_language_server="${LUA_LANGUAGE_SERVER:-}"

if [ -z "$lua_language_server" ]; then
  lua_language_server=$(command -v lua-language-server || true)
fi

if [ -z "$lua_language_server" ]; then
  printf '%s\n' "error: lua-language-server is not installed. Install it and re-run 'make lint'." >&2
  exit 1
fi

"$repo_root/scripts/generate-luals-addon.sh"

rm -rf "$log_dir"
mkdir -p "$log_dir"

cd "$repo_root"
exec "$lua_language_server" \
  --configpath=.luarc.json \
  --logpath="$log_dir" \
  --check=. \
  --checklevel="$check_level"
