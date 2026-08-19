#!/bin/bash
# uv aliases and a uv-flavored analog of venv.sh's directory convenience

alias uvr='uv run'
alias uva='uv add'
alias uvs='uv sync'

[ -z "${MY_UV_VENV_ROOT+set}" ] && export MY_UV_VENV_ROOT="$HOME/.uv-venvs"

# uv_venv_list
# Lists uv-managed venv names under $MY_UV_VENV_ROOT, via venv.sh's
# venv_list_dirs (uv.sh is sourced after venv.sh).
uv_venv_list() {
    venv_list_dirs "$MY_UV_VENV_ROOT"
}

# uv_venv_cd <name>
# Changes directory into $MY_UV_VENV_ROOT/<name>.
uv_venv_cd() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "dotfile: uv_venv_cd: usage: uv_venv_cd <name>" >&2
        return 1
    fi
    if [ -z "$MY_UV_VENV_ROOT" ]; then
        echo "dotfile: uv_venv_cd: MY_UV_VENV_ROOT not set" >&2
        return 1
    fi
    cd "$MY_UV_VENV_ROOT/$name" || return 1
}

# generate_uv_venv_aliases
# Generates a `so-<name>` alias for each uv-managed venv under $MY_UV_VENV_ROOT,
# via venv.sh's generate_so_aliases. uv.sh is sourced after venv.sh, so a
# venv and a uv-venv sharing a basename silently resolve to this uv alias
# (generate_so_aliases logs an overwrite diagnostic when that happens).
generate_uv_venv_aliases() {
    if ! declare -f generate_so_aliases >/dev/null 2>&1; then
        echo "dotfile: generate_uv_venv_aliases: generate_so_aliases not defined (venv.sh must be sourced first)" >&2
        return 1
    fi
    generate_so_aliases "$MY_UV_VENV_ROOT"
}

generate_uv_venv_aliases
