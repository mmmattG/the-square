SHELL := /bin/sh

LUA ?= $(shell command -v luajit 2>/dev/null || command -v lua 2>/dev/null)

.PHONY: all build install test e2e-test

all: build install

build:
	./scripts/build-mod.sh

install:
	./scripts/install-mod.sh

test:
	@if [ -z "$(LUA)" ]; then \
		echo "error: expected luajit or lua in PATH" >&2; \
		exit 1; \
	fi
	@for spec in tests/*_spec.lua; do \
		echo "==> $$spec"; \
		"$(LUA)" "$$spec" || exit 1; \
	done

# Runs Factorio itself and creates a fresh default save with this mod enabled.
# Set FACTORIO=/path/to/factorio if the binary is not on PATH or in a common install location.
e2e-test:
	./scripts/e2e-create-default-world.sh
