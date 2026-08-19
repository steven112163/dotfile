#!/bin/bash
# Classic virtualenv directory convenience: MY_VIRTUALENV_ROOT + so-<name> aliases

[ -z "${MY_VIRTUALENV_ROOT+set}" ] && export MY_VIRTUALENV_ROOT="$HOME/.virtualenvs"

# venv_list_dirs <root>
# Lists directory names directly under <root>, following symlinks.
# Shared by venv_list/uv_venv_list; venv.sh is sourced before uv.sh.
venv_list_dirs() {
    local root="$1"
    [ -d "$root" ] || return 0
    find -L "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
}

# venv_list
# Lists virtualenv names under $MY_VIRTUALENV_ROOT.
venv_list() {
    venv_list_dirs "$MY_VIRTUALENV_ROOT"
}

# generate_so_aliases <root>
# Generates a `so-<name>` alias for each <root>/<name>/bin/activate found.
# Shared by venv.sh and uv.sh; base.sh's DOTFILE_SHARED_INC lists venv before
# uv so this definition is in place before uv.sh calls it.
generate_so_aliases() {
    local root="$1"
    [ -d "$root" ] || return 0
    local venv_name activate_path quoted_path new_def existing_def venv_names
    venv_names="$(venv_list_dirs "$root")" || {
        echo "dotfile: generate_so_aliases: failed to list $root" >&2
        return 1
    }
    while IFS= read -r venv_name; do
        [ -z "$venv_name" ] && continue
        if [[ ! $venv_name =~ ^[A-Za-z0-9_.-]+$ ]]; then
            echo "dotfile: generate_so_aliases: skipping invalid venv name: $venv_name" >&2
            continue
        fi
        activate_path="$root/$venv_name/bin/activate"
        [ -f "$activate_path" ] || continue
        quoted_path="$(printf '%q' "$activate_path")"
        new_def=". $quoted_path"
        existing_def="$(alias "so-$venv_name" 2>/dev/null)"
        if [ -n "$existing_def" ]; then
            # `alias so-a='. path'` (bash) or `so-a='. path'` (zsh): strip
            # everything up to the first `=`, then the surrounding quotes.
            existing_def="${existing_def#*=}"
            existing_def="${existing_def#\'}"
            existing_def="${existing_def%\'}"
            [ "$existing_def" != "$new_def" ] &&
                echo "dotfile: generate_so_aliases: so-$venv_name already defined, overwriting" >&2
        fi
        # shellcheck disable=SC2139 # intentionally expands quoted_path at definition time
        alias "so-$venv_name=$new_def"
    done <<< "$venv_names"
    return 0
}

# generate_venv_aliases
# Generates a `so-<name>` alias for each virtualenv under $MY_VIRTUALENV_ROOT.
generate_venv_aliases() {
    generate_so_aliases "$MY_VIRTUALENV_ROOT"
    return 0
}

generate_venv_aliases
