#!/bin/bash
# Classic virtualenv directory convenience: MY_VIRTUALENV_ROOT + so-<name> aliases

[ -z "$MY_DEV_ROOT" ] && export MY_DEV_ROOT="$HOME/workspace"
[ -z "$MY_VIRTUALENV_ROOT" ] && export MY_VIRTUALENV_ROOT="$HOME/.virtualenvs"

# venv_list
# Lists virtualenv names under $MY_VIRTUALENV_ROOT.
venv_list() {
    [ -d "$MY_VIRTUALENV_ROOT" ] || return 0
    find "$MY_VIRTUALENV_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
}

# generate_venv_aliases
# Generates a `so-<name>` alias for each virtualenv under $MY_VIRTUALENV_ROOT.
generate_venv_aliases() {
    [ -d "$MY_VIRTUALENV_ROOT" ] || return 0
    local venv_dir venv_name
    for venv_dir in "$MY_VIRTUALENV_ROOT"/*/; do
        [ -f "${venv_dir}bin/activate" ] || continue
        venv_name="$(basename "$venv_dir")"
        # shellcheck disable=SC2139 # intentionally expands venv_dir at definition time
        alias "so-$venv_name=. \"${venv_dir}bin/activate\""
    done
}

generate_venv_aliases
