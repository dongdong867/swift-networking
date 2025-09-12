GITHOOKS := .githooks
HOOK := pre-commit
HOOK_SCRIPT := pre-commit-hook.sh

# Define tools that need to be installed via Homebrew
TOOLS := swiftlint swift-format

# Template for generating install-*-if-missing targets (must come before foreach)
define install_tool_template
.PHONY: install-$(1)-if-missing
install-$(1)-if-missing:
	@if ! command -v $(1) >/dev/null 2>&1; then \
	  echo "Installing $(1) via Homebrew..."; \
	  brew install $(1) || { echo "Failed to install $(1) via brew"; exit 1; }; \
	else \
	  echo "$(1) found"; \
	fi
endef

# Generate install targets for each tool using the template
$(foreach tool,$(TOOLS),$(eval $(call install_tool_template,$(tool))))

.PHONY: setup gen clean setup-xcode-build-server help $(foreach tool,$(TOOLS),install-$(tool)-if-missing)

help:
	@echo "Usage: make setup"
	@echo
	@echo "setup - Install/enable project-local pre-commit hook and ensure required tools (via Homebrew)"
	@echo "clean - Remove project-local hooks and unset git core.hooksPath"

# Single entrypoint: setup installs missing tools (via Homebrew), writes the hook, and enables it.
setup:
	@set -euo pipefail; \
	make check-git; \
	make check-brew; \
	make install-swiftlint-if-missing; \
	make install-swift-format-if-missing; \
	make setup-git-hook;

clean:
	-@git config --unset core.hooksPath || true
	-@rm -rf $(GITHOOKS)
	@echo "Cleaned project-local hooks and unset core.hooksPath"

check-git:
	@if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
	  echo "Error: not inside a git repository."; exit 1; \
	fi

check-brew:
	@if ! command -v brew >/dev/null 2>&1; then \
	  echo "Error: Homebrew is not installed. Please install Homebrew first: https://brew.sh/"; exit 1; \
	fi

setup-git-hook:
	@set -euo pipefail; \
	mkdir -p $(GITHOOKS); \
	cp $(HOOK_SCRIPT) $(GITHOOKS)/$(HOOK); \
	chmod +x $(GITHOOKS)/$(HOOK); \
	git config core.hooksPath $(GITHOOKS); \
	echo "Installed and enabled project-local pre-commit hook at $(GITHOOKS)/$(HOOK)"
