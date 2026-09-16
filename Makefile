# arch-install — Vanilla Arch Linux installer
#
# Usage (on the live ISO):
#   make install            Run the full installation pipeline
#   make packages           Re-run just the package selection phase (as root)
#   make user               Re-run just the user setup phase (as your user)
#   make check              Lint all scripts (bash -n + shellcheck)
#   make list               Print the package catalog
#
# You can override the target disk and swap size:
#   make install DISK=/dev/sda SWAP=4G

DISK  ?=
SWAP  ?=
PHASE ?=

SHELL      := /bin/bash
REPO_DIR   := $(shell pwd)
BIN_DIR    := $(REPO_DIR)/bin

.DEFAULT_GOAL := help

.PHONY: help install packages user check list test test-full

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

install: ## Full install (run from live ISO)
	@[ -n "$(DISK)" ] && DISK_FLAG="--disk $(DISK)" || DISK_FLAG=""; \
	[ -n "$(SWAP)" ] && SWAP_FLAG="--swap $(SWAP)" || SWAP_FLAG=""; \
	sudo "$(BIN_DIR)/arch-install.sh" $$DISK_FLAG $$SWAP_FLAG

packages: ## Re-run package selection (as root, after first boot)
	@sudo "$(BIN_DIR)/40-packages.sh"

user: ## Re-run user-level setup (as normal user, after first boot)
	@bash "$(BIN_DIR)/50-user.sh"

check: ## Syntax-check all scripts
	@echo "Running bash -n ..."
	@for f in "$(BIN_DIR)"/*.sh "$(BIN_DIR)"/lib/*.sh config/settings.sh; do \
		bash -n "$$f" || exit 1; \
	done
	@command -v shellcheck >/dev/null 2>&1 && \
		echo "Running shellcheck ..." && \
		shellcheck "$(BIN_DIR)"/*.sh "$(BIN_DIR)"/lib/*.sh || \
		echo "(shellcheck not installed, skipping)"
	@echo "All scripts valid."

list: ## Print the package catalog
	@column -t -s, "$(REPO_DIR)/packages/apps.csv" | grep -v '^\s*#'

test: ## Build pod + run quick smoke tests in the arch container
	@bash tests/run-pod.sh
	@podman exec -it arch-install-test \
		bash /opt/arch-install/tests/manual-test.sh

test-full: ## Build pod + run smoke tests including 40/50 (installs packages)
	@bash tests/run-pod.sh
	@podman exec -it arch-install-test \
		bash /opt/arch-install/tests/manual-test.sh --full