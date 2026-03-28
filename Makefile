SHELL := /bin/sh

.PHONY: build install

build:
	./scripts/build-mod.sh

install:
	./scripts/install-mod.sh
