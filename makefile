GITHOOKS := .githooks
HOOK := pre-commit
HOOK_SCRIPT := pre-commit-hook.sh

.PHONY: setup build test lint format format-check clean help

help:
	@echo "Usage:"
	@echo "  make setup        — Install tools (via Homebrew) and enable pre-commit hook"
	@echo "  make build        — Build all targets"
	@echo "  make test         — Run all tests"
	@echo "  make lint         — Lint Swift files with swiftlint"
	@echo "  make format       — Format Swift files in place"
	@echo "  make format-check — Check formatting without modifying (CI)"
	@echo "  make clean        — Remove build artifacts and project-local hooks"

setup:
	@set -euo pipefail; \
	make check-git; \
	make check-brew; \
	make install-swiftlint-if-missing; \
	make install-swift-format-if-missing; \
	make setup-git-hook;

build:
	swift build

test:
	swift test

lint:
	@if ! command -v swiftlint >/dev/null 2>&1; then \
	  echo "swiftlint not found. Run: make setup"; exit 1; \
	fi; \
	swiftlint lint Sources Tests

format:
	@if ! command -v swift-format >/dev/null 2>&1; then \
	  echo "swift-format not found. Run: make setup"; exit 1; \
	fi; \
	swift-format format --in-place --recursive Sources Tests

format-check:
	@if ! command -v swift-format >/dev/null 2>&1; then \
	  echo "swift-format not found. Run: make setup"; exit 1; \
	fi; \
	swift-format lint --recursive Sources Tests

clean:
	-@swift package clean 2>/dev/null || true
	-@git config --unset core.hooksPath 2>/dev/null || true
	-@rm -rf $(GITHOOKS)
	@echo "Cleaned build artifacts and project-local hooks"

check-git:
	@if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
	  echo "Error: not inside a git repository."; exit 1; \
	fi

check-brew:
	@if ! command -v brew >/dev/null 2>&1; then \
	  echo "Error: Homebrew is not installed. Please install Homebrew first: https://brew.sh/"; exit 1; \
	fi

install-swiftlint-if-missing:
	@if ! command -v swiftlint >/dev/null 2>&1; then \
	  echo "Installing swiftlint via Homebrew..."; \
	  brew install swiftlint || { echo "Failed to install swiftlint via brew"; exit 1; }; \
	else \
	  echo "swiftlint found"; \
	fi

install-swift-format-if-missing:
	@if ! command -v swift-format >/dev/null 2>&1; then \
	  echo "Installing swift-format via Homebrew..."; \
	  brew install swift-format || { echo "Failed to install swift-format via brew"; exit 1; }; \
	else \
	  echo "swift-format found"; \
	fi

setup-git-hook:
	@set -euo pipefail; \
	mkdir -p $(GITHOOKS); \
	cp $(HOOK_SCRIPT) $(GITHOOKS)/$(HOOK); \
	chmod +x $(GITHOOKS)/$(HOOK); \
	git config core.hooksPath $(GITHOOKS); \
	echo "Installed and enabled project-local pre-commit hook at $(GITHOOKS)/$(HOOK)"
