# coderun developer tasks.
#
# Run `make` or `make help` to see the available targets.

SHELL := /bin/bash

.PHONY: help build check test test-unix test-update test-installer test-macos test-windows lint

help:
	@printf 'coderun developer tasks:\n\n'
	@printf '  make build           Build generated runners from src/\n'
	@printf '  make check           Run consistency checks\n'
	@printf '  make test            Run all Unix test suites\n'
	@printf '  make test-unix       Run the Unix behaviour tests\n'
	@printf '  make test-update     Run the Unix update tests\n'
	@printf '  make test-installer  Run the Unix installer tests\n'
	@printf '  make test-macos      Simulate macOS compiler selection\n'
	@printf '  make test-windows    Run the PowerShell suites (requires pwsh)\n'
	@printf '  make lint            Run ShellCheck on the Bash sources\n'

build:
	@./scripts/build.sh

check:
	@./scripts/check.sh

test: test-unix test-update test-installer

test-unix:
	@./tests/run-bash-tests.sh

test-update:
	@./tests/update-bash-tests.sh

test-installer:
	@./tests/installer-tests.sh

test-macos:
	@CODERUN_TEST_OS=Darwin ./tests/run-bash-tests.sh

test-windows:
	@if command -v pwsh >/dev/null 2>&1; then \
		pwsh -NoProfile -File tests/run-powershell-tests.ps1; \
		pwsh -NoProfile -File tests/installer-tests.ps1; \
	else \
		echo "SKIP: pwsh not found."; \
	fi

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -S warning \
			bin/coderun \
			install.sh \
			install-mac.sh \
			scripts/*.sh \
			src/unix/*.sh \
			tests/*.sh \
			tests/lib/*.sh; \
	else \
		echo "SKIP: shellcheck not found."; \
	fi
