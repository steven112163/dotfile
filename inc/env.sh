#!/bin/bash
# PATH/LD_LIBRARY_PATH registration and dedup helpers, plus self-update

# register_path <dir>
# Prepends <dir> to PATH if it exists.
register_path() {
    local dir="$1"
    if [ -z "$dir" ]; then
        echo "dotfile: register_path: path not specified" >&2
        return 1
    fi
    if [ ! -d "$dir" ]; then
        echo "dotfile: register_path: $dir does not exist" >&2
        return 1
    fi
    PATH="$dir${PATH:+:$PATH}"
    export PATH
}

# register_library <dir>
# Prepends <dir> to LD_LIBRARY_PATH if it exists.
register_library() {
    local dir="$1"
    if [ -z "$dir" ]; then
        echo "dotfile: register_library: path not specified" >&2
        return 1
    fi
    if [ ! -d "$dir" ]; then
        echo "dotfile: register_library: $dir does not exist" >&2
        return 1
    fi
    LD_LIBRARY_PATH="$dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export LD_LIBRARY_PATH
}

# register_path_and_library <dir>
# Registers <dir>/bin to PATH and <dir>/lib to LD_LIBRARY_PATH.
register_path_and_library() {
    local dir="$1"
    register_path "$dir/bin" || return 1
    register_library "$dir/lib" || return 1
}

_uniqueify_path_bash() {
    local env_var_name="$1"
    local old_ifs="$IFS" component path_array=()
    IFS=':' read -ra path_array <<< "${!env_var_name}"
    IFS="$old_ifs"

    local -A seen=()
    local unique=()
    for component in "${path_array[@]}"; do
        [ -z "$component" ] && continue
        if [ -z "${seen[$component]:-}" ]; then
            seen[$component]=1
            unique+=("$component")
        fi
    done
    local IFS=':'
    echo "${unique[*]}"
}

# shellcheck disable=SC2296 # zsh-only parameter expansion, never parsed by bash at runtime
# `component` (not `path`): zsh ties `path` to `PATH` as a special parameter,
# so `local path` shadows that tie and reads back empty when env_var_name=PATH.
_uniqueify_path_zsh() {
    local env_var_name="$1"
    local component
    local path_array=("${(@s/:/)${(P)env_var_name}}")

    typeset -A seen
    local unique=()
    for component in "${path_array[@]}"; do
        [ -z "$component" ] && continue
        if [ -z "${seen[$component]:-}" ]; then
            seen[$component]=1
            unique+=("$component")
        fi
    done
    local IFS=':'
    echo "${unique[*]}"
}

# uniqueify_path <env-var-name>
# Prints <env-var-name>'s colon-separated value with duplicates and empty
# components removed.
uniqueify_path() {
    if [ -n "$ZSH_VERSION" ]; then
        _uniqueify_path_zsh "$@"
    elif [ -n "$BASH_VERSION" ]; then
        _uniqueify_path_bash "$@"
    else
        echo "dotfile: uniqueify_path: unsupported shell" >&2
        return 1
    fi
}

# uniqueify_PATH
# Dedupes PATH in place; leaves PATH untouched if the dedup itself fails.
uniqueify_PATH() {
    local new
    new="$(uniqueify_path PATH)" && PATH="$new" && export PATH
}

# uniqueify_LD_LIBRARY_PATH
# Dedupes LD_LIBRARY_PATH in place; leaves it untouched if the dedup fails.
uniqueify_LD_LIBRARY_PATH() {
    local new
    new="$(uniqueify_path LD_LIBRARY_PATH)" && LD_LIBRARY_PATH="$new" && export LD_LIBRARY_PATH
}

# env_self_update
# Fast-forward pulls this dotfile repo in place; refuses on a dirty working
# tree or if DOTFILE_ROOT isn't a git repo.
env_self_update() {
    if [ -z "$DOTFILE_ROOT" ]; then
        echo "dotfile: env_self_update: DOTFILE_ROOT not set" >&2
        return 1
    fi
    if ! git -C "$DOTFILE_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        echo "dotfile: env_self_update: $DOTFILE_ROOT is not a git repo" >&2
        return 1
    fi
    local status
    status="$(git -C "$DOTFILE_ROOT" status --porcelain)" || {
        echo "dotfile: env_self_update: git status failed" >&2
        return 1
    }
    if [ -n "$status" ]; then
        echo "dotfile: env_self_update: working tree not clean, aborting" >&2
        return 1
    fi
    git -C "$DOTFILE_ROOT" pull --ff-only
}
