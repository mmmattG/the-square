SHELL := /bin/sh

LUA ?= $(shell command -v luajit 2>/dev/null || command -v lua 2>/dev/null)

.PHONY: build install test tools-bootstrap luals-meta lint fmtk-package factorio-tools-install factorio-tools-dat2json factorio-tools-desync

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

tools-bootstrap:
	./scripts/bootstrap-node-toolchain.sh

luals-meta:
	./scripts/generate-luals-addon.sh

lint:
	./scripts/lua-ls-check.sh

fmtk-package:
	./scripts/fmtk-package.sh

factorio-tools-install:
	./scripts/install-factorio-tools.sh

factorio-tools-dat2json:
	./scripts/factorio-tools.sh dat2json $(ARGS)

factorio-tools-desync:
	./scripts/factorio-tools.sh desync $(ARGS)
