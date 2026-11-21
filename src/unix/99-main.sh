# shellcheck shell=bash
# =============================================================================
# 99-main.sh - Entry point
#
# Every module above defines constants and functions. This final line starts
# the CLI. Keeping the call in its own module makes the generated runner's
# entry point obvious and keeps module loading free of side effects.
# =============================================================================

main "$@"
