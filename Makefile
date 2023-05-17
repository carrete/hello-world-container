# -*- coding: utf-8; mode: makefile-gmake; -*-

MAKEFLAGS += --warn-undefined-variables

SHELL := bash
.SHELLFLAGS := -euo pipefail -c

HERE := $(shell cd -P -- $(shell dirname -- $$0) && pwd -P)

CONTAINER_SLUG := carrete/hello-world-container
CONTAINER_REGISTRY := ghcr.io
CONTAINER_VERSION := $(shell git rev-parse HEAD)

PORT ?= 3000

.PHONY: all
all: build

.PHONY: has-command-%
has-command-%:
	@$(if $(shell command -v $* 2> /dev/null),,$(error The command $* does not exist in PATH))

.PHONY: is-defined-%
is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

.PHONY: is-repo-clean
is-repo-clean: has-command-git
	@git diff-index --quiet HEAD --

.PHONY: login
login: has-command-podman is-defined-CONTAINER_REGISTRY is-defined-GITHUB_USERNAME is-defined-GITHUB_PASSWORD
	@echo $(GITHUB_PASSWORD) | podman login --username $(GITHUB_USERNAME) --password-stdin $(CONTAINER_REGISTRY)

.PHONY: build
build: has-command-podman is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION
	@podman build -t $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION) -f Containerfile .

.PHONY: push
push: is-repo-clean has-command-podman is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION build login
	@podman push $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)

.PHONY: run
run: is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION is-defined-PORT build
	@podman run --init --rm                                                 \
	    --env PORT=$(PORT)                                                  \
	    --publish $(PORT):$(PORT)                                           \
	$(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)            \
	make run

.PHONY: shell
shell: is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION is-defined-PORT build
	@podman run --init --rm -it                                             \
	    --env PORT=$(PORT)                                                  \
	    --publish $(PORT):$(PORT)                                           \
	    --volume $(PWD)/hello-world-container:/opt/hello-world-container    \
	$(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)            \
	make shell

FLY := $(HERE)/contrib/fly

.PHONY: create-infra
create-infra: is-defined-FLY_ORGANIZATION
	@APPS="$$($(FLY) apps list)";                                           \
	if ! echo $$APPS | grep -cq hello-world-container; then                 \
	    $(FLY) apps create hello-world-container -o $(FLY_ORGANIZATION);    \
	fi

.PHONY: destroy-infra
destroy-infra:
	@APPS="$$($(FLY) apps list)";                                           \
	if echo $$APPS | grep -cq hello-world-container; then                   \
	    $(FLY) apps destroy hello-world-container -y;                       \
	fi

.PHONY: deploy
deploy: is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION create-infra
	@$(FLY) deploy -c hello-world-container.toml                            \
	  -i $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)       \
