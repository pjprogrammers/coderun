# shellcheck shell=bash
# =============================================================================
# 50-completions.sh - Shell completion generators
#
# Each branch prints a self-contained completion script. Users can install the
# output with their shell's normal completion mechanism.
# =============================================================================

show_completions() {
    case "$1" in
        bash)
            cat <<'EOF'
# bash completion for coderun
_coderun() {
    local cur opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts="-h --help -v --version --list --verbose --check --strict --info --check-update --update --uninstall --compile --clean -o --output --runtime --time -q --quiet --completions"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
    fi
    COMPREPLY+=( $(compgen -f -- "$cur") )
}
complete -F _coderun coderun
EOF
            ;;
        zsh)
            cat <<'EOF'
#compdef coderun
_coderun() {
    _arguments \
        '(-h --help)'{-h,--help}'[show help]' \
        '(-v --version)'{-v,--version}'[show version]' \
        '--list[list supported languages]' \
        '--verbose[show tool status with --list]' \
        '--check[check toolchains]' \
        '--strict[fail when tools are missing]' \
        '--info[show system information]' \
        '--check-update[check for a newer release]' \
        '--update[update coderun]' \
        '--uninstall[remove coderun]' \
        '--compile[compile only]' \
        '--clean[remove build artifacts]' \
        '(-o --output)'{-o,--output}'[set output artifact]:file:_files' \
        '--runtime[choose JavaScript/TypeScript runtime]:runtime:(node bun deno)' \
        '--time[report elapsed time]' \
        '(-q --quiet)'{-q,--quiet}'[suppress informational messages]' \
        '--completions[print completions]:shell:(bash zsh fish powershell)' \
        '*:file:_files'
}
_coderun "$@"
EOF
            ;;
        fish)
            cat <<'EOF'
# fish completion for coderun
complete -c coderun -f
complete -c coderun -s h -l help -d 'Show help'
complete -c coderun -s v -l version -d 'Show version'
complete -c coderun -l list -d 'List supported languages'
complete -c coderun -l verbose -d 'Show tool status with --list'
complete -c coderun -l check -d 'Check toolchains'
complete -c coderun -l strict -d 'Fail when tools are missing'
complete -c coderun -l info -d 'Show system information'
complete -c coderun -l check-update -d 'Check for updates'
complete -c coderun -l update -d 'Update coderun'
complete -c coderun -l uninstall -d 'Remove coderun'
complete -c coderun -l compile -d 'Compile only'
complete -c coderun -l clean -d 'Remove build artifacts'
complete -c coderun -s o -l output -r -d 'Set output artifact'
complete -c coderun -l runtime -r -a 'node bun deno' -d 'Choose runtime'
complete -c coderun -l time -d 'Report elapsed time'
complete -c coderun -s q -l quiet -d 'Suppress informational messages'
complete -c coderun -l completions -r -a 'bash zsh fish powershell' -d 'Print completions'
complete -c coderun -F
EOF
            ;;
        powershell|pwsh)
            cat <<'EOF'
# PowerShell completion for coderun
Register-ArgumentCompleter -Native -CommandName coderun -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $options = @(
        '-h', '--help', '-v', '--version', '--list', '--verbose', '--check',
        '--strict', '--info', '--check-update', '--update', '--uninstall',
        '--compile', '--clean', '-o', '--output', '--runtime', '--time',
        '-q', '--quiet', '--completions'
    )
    $options | Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
}
EOF
            ;;
        *)
            echo "Error: unknown shell: $1"
            echo "Supported shells: bash, zsh, fish, powershell."
            return 1
            ;;
    esac
}
