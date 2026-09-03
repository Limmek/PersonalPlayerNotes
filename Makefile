# Local developer workflow for PersonalPlayerNotes.
#
# Mirrors the checks run in .github/workflows/ci.yml so problems are caught
# before pushing. Requires: lua5.1 (or lua), a local `stylua` binary on PATH
# (or set STYLUA=/path/to/stylua), and luacheck on PATH.
#
# On Windows, run these via Git Bash/WSL, or invoke the equivalent commands
# directly (see README.md / CONTRIBUTING.md). `make dev` is a Windows-friendly
# alias that runs the PowerShell pipeline in Tools/dev.ps1.

LUA        ?= lua5.1
STYLUA     ?= stylua
LUACHECK   ?= luacheck

LUA_FILES  := PersonalPlayerNotes.lua PersonalPlayerNotesConfig.lua PersonalPlayerNotesUtils.lua \
              Sounds/Manifest.lua \
              Tests/test_utils.lua Tests/test_config.lua Tests/test_main.lua Tests/support/bootstrap.lua \
              Locales/enUS.lua Locales/zhCN.lua Tools/validate-toc.lua Tools/generate-sounds-manifest.lua

TEST_FILES := Tests/test_utils.lua Tests/test_config.lua Tests/test_main.lua

.PHONY: format format-check lint test validate build check dev clean

format: ## Format all Lua files in-place with StyLua
	$(STYLUA) $(LUA_FILES)

format-check: ## Check formatting without writing changes (same as CI)
	$(STYLUA) --check $(LUA_FILES)

lint: ## Run Luacheck
	$(LUACHECK) .

test: ## Run the pure-Lua unit test suite
	@for f in $(TEST_FILES); do \
		echo "-- $$f --"; \
		$(LUA) $$f || exit 1; \
	done

validate: ## Validate PersonalPlayerNotes.toc (metadata, referenced files, duplicates)
	$(LUA) Tools/validate-toc.lua

sounds: ## Regenerate Sounds/Manifest.lua from the files actually in Sounds/
	$(LUA) Tools/generate-sounds-manifest.lua

sounds-check: ## Verify Sounds/Manifest.lua is up to date (same as CI), no write
	$(LUA) Tools/generate-sounds-manifest.lua --check

build: ## Build a local, unsigned addon zip without uploading anywhere (requires BigWigsMods/packager's release.sh in PATH or .release/)
	@if [ ! -f .release/release.sh ]; then \
		echo "Fetching release.sh from BigWigsMods/packager@v2.5.1..."; \
		mkdir -p .release; \
		curl -s -o .release/release.sh https://raw.githubusercontent.com/BigWigsMods/packager/v2.5.1/release.sh; \
		chmod +x .release/release.sh; \
	fi
	.release/release.sh -d -p 0 -w 0 -a 0 -m .pkgmeta

check: format-check lint test validate sounds-check ## Run every local check (does not build a package)

dev: ## Run the full local Windows dev pipeline (format, lint, test, validate, sounds-check, build)
	powershell -NoProfile -ExecutionPolicy Bypass -File Tools/dev.ps1

clean: ## Remove local build output
	rm -rf .release
