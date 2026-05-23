SHELL := /bin/sh

LUA ?= $(shell command -v luajit 2>/dev/null || command -v lua 2>/dev/null)

.PHONY: all build install test unit-test e2e-load-test e2e-test

all: build install

build:
	./scripts/build-mod.sh

install:
	./scripts/install-mod.sh

test: unit-test e2e-test

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
