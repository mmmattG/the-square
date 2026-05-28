#!/bin/sh

set -eu

os=$(uname -s 2>/dev/null || printf unknown)

if [ "$os" = "Darwin" ]; then
  printf '%s\n' "$HOME/Library/Application Support/factorio/mods"
  exit 0
fi

if [ "$os" = "Linux" ]; then
  if command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    win_path=$(cmd.exe /C "echo %APPDATA%\Factorio\mods" 2>/dev/null | tr -d '\r')

    if [ -n "$win_path" ]; then
      wslpath -u "$win_path"
      exit 0
    fi
  fi

  printf '%s\n' "$HOME/.factorio/mods"
  exit 0
fi

case "$os" in
  MINGW*|MSYS*|CYGWIN*)
    if [ -n "${APPDATA:-}" ]; then
      printf '%s\n' "$APPDATA/Factorio/mods"
      exit 0
    fi
    ;;
esac

printf '%s\n' "$HOME/.factorio/mods"
