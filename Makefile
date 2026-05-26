SHELL := /bin/sh

LUA ?= $(shell command -v luajit 2>/dev/null || command -v lua 2>/dev/null)
LUAC ?= $(shell command -v luac 2>/dev/null || command -v luac5.4 2>/dev/null || command -v luac5.3 2>/dev/null || command -v luac5.2 2>/dev/null)

.PHONY: all build install test typecheck unit-test e2e-load-test e2e-test e2e-screenshot-test e2e-placement-preview-screenshot-test

all: build install

build:
	./scripts/build-mod.sh

install:
	./scripts/install-mod.sh

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

# Runs Factorio with graphics and writes a rendered placement-preview screenshot artifact.
# Set E2E_PLACEMENT_PREVIEW_SCREENSHOT_PATH=/path/to/placement-preview.png to override the default build/e2e-placement-preview.png.
e2e-placement-preview-screenshot-test:
	@tmp=$$(mktemp); \
	if ./scripts/e2e-placement-preview-screenshot.sh >$$tmp 2>&1; then \
		cat $$tmp; \
		rm -f $$tmp; \
		echo "PASS e2e placement preview screenshot test"; \
	else \
		status=$$?; \
		echo "FAIL e2e placement preview screenshot test" >&2; \
		cat $$tmp >&2; \
		rm -f $$tmp; \
		exit $$status; \
	fi
