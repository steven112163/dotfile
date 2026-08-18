#!/bin/bash
# uv aliases and a uv-flavored analog of venv.sh's directory convenience

alias uvr='uv run'
alias uva='uv add'
alias uvs='uv sync'

[ -z "$MY_UV_VENV_ROOT" ] && export MY_UV_VENV_ROOT="$HOME/.uv-venvs"

# uv_venv_list
# Lists uv-managed venv names under $MY_UV_VENV_ROOT.
uv_venv_list() {
    [ -d "$MY_UV_VENV_ROOT" ] || return 0
    find "$MY_UV_VENV_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
}

# uv_venv_cd <name>
# Changes directory into $MY_UV_VENV_ROOT/<name>.
uv_venv_cd() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "dotfile: uv_venv_cd: usage: uv_venv_cd <name>" >&2
        return 1
    fi
    cd "$MY_UV_VENV_ROOT/$name" || return 1
}

# generate_uv_venv_aliases
# Generates a `so-<name>` alias for each uv-managed venv under $MY_UV_VENV_ROOT.
generate_uv_venv_aliases() {
    [ -d "$MY_UV_VENV_ROOT" ] || return 0
    local venv_dir venv_name
    for venv_dir in "$MY_UV_VENV_ROOT"/*/; do
        [ -f "${venv_dir}bin/activate" ] || continue
        venv_name="$(basename "$venv_dir")"
        # shellcheck disable=SC2139 # intentionally expands venv_dir at definition time
        alias "so-$venv_name=. \"${venv_dir}bin/activate\""
    done
}

generate_uv_venv_aliases
