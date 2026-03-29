SHELL := /bin/sh

LUA ?= $(shell command -v luajit 2>/dev/null || command -v lua 2>/dev/null)

.PHONY: build install test

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
