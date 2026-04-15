SHELL := /bin/sh

FACTORIO_MODS_DIR ?= $(shell \
	if [ -d "$$HOME/Library/Application Support/factorio/mods" ]; then \
		printf '%s' "$$HOME/Library/Application Support/factorio/mods"; \
	elif [ -d "$$HOME/.factorio/mods" ]; then \
		printf '%s' "$$HOME/.factorio/mods"; \
	elif grep -qi microsoft /proc/version 2>/dev/null; then \
		win_user=$$(cd /mnt/c 2>/dev/null && cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r'); \
		if [ -n "$$win_user" ] && [ -d "/mnt/c/Users/$$win_user/AppData/Roaming/Factorio/mods" ]; then \
			printf '%s' "/mnt/c/Users/$$win_user/AppData/Roaming/Factorio/mods"; \
		fi; \
	fi)

BASE_MOD_DIR := mods/base
SPACE_AGE_MOD_DIR := mods/space-age
MOD_DIRS := $(BASE_MOD_DIR) $(SPACE_AGE_MOD_DIR)

.PHONY: build build-base build-space-age install install-base install-space-age deploy-space-age test test-base test-space-age lint lint-base lint-space-age fmtk-package fmtk-package-base fmtk-package-space-age tools-bootstrap tools-bootstrap-base tools-bootstrap-space-age luals-meta luals-meta-base luals-meta-space-age

build: build-base build-space-age

build-base:
	$(MAKE) -C "$(BASE_MOD_DIR)" build

build-space-age:
	$(MAKE) -C "$(SPACE_AGE_MOD_DIR)" build

install: install-base install-space-age

install-base:
	$(MAKE) -C "$(BASE_MOD_DIR)" install FACTORIO_MODS_DIR="$(FACTORIO_MODS_DIR)"

install-space-age:
	$(MAKE) -C "$(SPACE_AGE_MOD_DIR)" install FACTORIO_MODS_DIR="$(FACTORIO_MODS_DIR)"

deploy-space-age: install

test: test-base test-space-age

test-base:
	$(MAKE) -C "$(BASE_MOD_DIR)" test

test-space-age:
	$(MAKE) -C "$(SPACE_AGE_MOD_DIR)" test

lint: lint-base lint-space-age

lint-base:
	$(MAKE) -C "$(BASE_MOD_DIR)" lint

lint-space-age:
	$(MAKE) -C "$(SPACE_AGE_MOD_DIR)" lint

fmtk-package: fmtk-package-base fmtk-package-space-age

fmtk-package-base:
	$(MAKE) -C "$(BASE_MOD_DIR)" fmtk-package

fmtk-package-space-age:
	$(MAKE) -C "$(SPACE_AGE_MOD_DIR)" fmtk-package

tools-bootstrap: tools-bootstrap-base tools-bootstrap-space-age

tools-bootstrap-base:
	$(MAKE) -C "$(BASE_MOD_DIR)" tools-bootstrap

tools-bootstrap-space-age:
	$(MAKE) -C "$(SPACE_AGE_MOD_DIR)" tools-bootstrap

luals-meta: luals-meta-base luals-meta-space-age

luals-meta-base:
	$(MAKE) -C "$(BASE_MOD_DIR)" luals-meta

luals-meta-space-age:
	$(MAKE) -C "$(SPACE_AGE_MOD_DIR)" luals-meta
