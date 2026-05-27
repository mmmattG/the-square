SHELL := /bin/sh

LUA ?= $(shell command -v luajit 2>/dev/null || command -v lua 2>/dev/null)
LUAC ?= $(shell command -v luac 2>/dev/null || command -v luac5.4 2>/dev/null || command -v luac5.3 2>/dev/null || command -v luac5.2 2>/dev/null)
MOD_NAME := $(shell python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("info.json").read_text())["name"])')
MOD_VERSION := $(shell python3 -c 'import json, pathlib; print(json.loads(pathlib.Path("info.json").read_text())["version"])')
ARTIFACT := build/$(MOD_NAME)_$(MOD_VERSION).zip
DETECTED_WINDOWS_FACTORIO_MODS_DIR := $(shell if command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then win_path=$$(cmd.exe /C "echo %APPDATA%\Factorio\mods" 2>/dev/null | tr -d '\r'); if [ -n "$$win_path" ]; then wslpath -u "$$win_path"; fi; fi)
DETECTED_FACTORIO_MODS_DIR := $(or $(DETECTED_WINDOWS_FACTORIO_MODS_DIR),$(HOME)/.factorio/mods)
FACTORIO_MODS_DIR ?= $(DETECTED_FACTORIO_MODS_DIR)

.PHONY: all build install test typecheck unit-test e2e-load-test e2e-test e2e-screenshot-test playtest

all: build install

build:
	./scripts/build-mod.sh

install: build
	@if [ -z "$(FACTORIO_MODS_DIR)" ]; then \
		echo "error: could not detect Factorio mods directory; set FACTORIO_MODS_DIR=/path/to/mods" >&2; \
		exit 1; \
	fi
	@mkdir -p "$(FACTORIO_MODS_DIR)"
	@cp "$(ARTIFACT)" "$(FACTORIO_MODS_DIR)/"
	@find "$(FACTORIO_MODS_DIR)" -maxdepth 1 \( -name "$(MOD_NAME)" -o -name "$(MOD_NAME)_*.zip" \) ! -name "$(notdir $(ARTIFACT))" -exec rm -rf {} + 2>/dev/null || true
	@if [ -n "$$(find "$(FACTORIO_MODS_DIR)" -maxdepth 1 \( -name "$(MOD_NAME)" -o -name "$(MOD_NAME)_*.zip" \) ! -name "$(notdir $(ARTIFACT))" -print -quit)" ]; then \
		echo "warning: could not remove every old $(MOD_NAME) install; close Factorio if Windows has a zip locked" >&2; \
	fi
	@printf 'Installed %s to %s\n' "$(notdir $(ARTIFACT))" "$(FACTORIO_MODS_DIR)"

test: unit-test e2e-test

typecheck:
	@if [ -z "$(LUAC)" ] && [ -z "$(LUA)" ]; then \
		echo "error: expected luac, luajit, or lua in PATH" >&2; \
		exit 1; \
	fi
	@find . -name '*.lua' -type f -print | while IFS= read -r file; do \
		if [ -n "$(LUAC)" ]; then \
			"$(LUAC)" -p "$$file" || exit $$?; \
		else \
			LUA_CHECK_FILE="$$file" "$(LUA)" -e 'assert(loadfile(os.getenv("LUA_CHECK_FILE")))' || exit $$?; \
		fi; \
	done
	@echo "PASS lua syntax check"

unit-test:
	@if [ -z "$(LUA)" ]; then \
		echo "error: expected luajit or lua in PATH" >&2; \
		exit 1; \
	fi
	@for spec in tests/*_spec.lua; do \
		tmp=$$(mktemp); \
		if "$(LUA)" "$$spec" >$$tmp 2>&1; then \
			rm -f $$tmp; \
		else \
			status=$$?; \
			echo "FAIL $$spec" >&2; \
			cat $$tmp >&2; \
			rm -f $$tmp; \
			exit $$status; \
		fi; \
	done
	@echo "PASS unit tests"

# Runs Factorio itself and verifies the mod reaches save creation without prototype/load errors.
# Set FACTORIO=/path/to/factorio if the binary is not on PATH or in a common install location.
e2e-load-test:
	@tmp=$$(mktemp); \
	if ./scripts/e2e-load-mod.sh >$$tmp 2>&1; then \
		rm -f $$tmp; \
		echo "PASS e2e load test"; \
	else \
		status=$$?; \
		echo "FAIL e2e load test" >&2; \
		cat $$tmp >&2; \
		rm -f $$tmp; \
		exit $$status; \
	fi

# Runs Factorio itself and creates a fresh default save with this mod enabled.
# Set FACTORIO=/path/to/factorio if the binary is not on PATH or in a common install location.
e2e-test: e2e-load-test
	@tmp=$$(mktemp); \
	if ./scripts/e2e-create-default-world.sh >$$tmp 2>&1; then \
		rm -f $$tmp; \
		echo "PASS e2e create default world test"; \
	else \
		status=$$?; \
		echo "FAIL e2e create default world test" >&2; \
		cat $$tmp >&2; \
		rm -f $$tmp; \
		exit $$status; \
	fi

# Runs Factorio with graphics and writes a rendered gameplay screenshot artifact.
# Set E2E_SCREENSHOT_PATH=/path/to/world.png to override the default build/e2e-world.png.
e2e-screenshot-test:
	@tmp=$$(mktemp); \
	if ./scripts/e2e-create-default-world-screenshot.sh >$$tmp 2>&1; then \
		cat $$tmp; \
		rm -f $$tmp; \
		echo "PASS e2e screenshot test"; \
	else \
		status=$$?; \
		echo "FAIL e2e screenshot test" >&2; \
		cat $$tmp >&2; \
		rm -f $$tmp; \
		exit $$status; \
	fi

# Creates and launches an isolated human-in-the-loop playtest save with helper controls.
# Set PLAYTEST_NO_LAUNCH=1 to only create the save.
playtest:
	./scripts/playtest-world.sh
