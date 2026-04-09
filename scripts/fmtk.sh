#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

if [ ! -x "$repo_root/node_modules/.bin/fmtk" ]; then
  printf '%s\n' "error: missing repo-local Node tools. Run 'make tools-bootstrap' first." >&2
  exit 1
fi

cd "$repo_root"
exec npm exec -- fmtk "$@"
