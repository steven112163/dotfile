#!/bin/bash
# PATH/LD_LIBRARY_PATH registration and dedup helpers, plus self-update

# registerPath <dir>
# Prepends <dir> to PATH if it exists.
registerPath() {
    local dir="$1"
    if [ -z "$dir" ]; then
        echo "dotfile: registerPath: path not specified" >&2
        return 1
    fi
    if [ ! -d "$dir" ]; then
        echo "dotfile: registerPath: $dir does not exist" >&2
        return 1
    fi
    export PATH="$dir:$PATH"
}

# registerLibrary <dir>
# Prepends <dir> to LD_LIBRARY_PATH if it exists.
registerLibrary() {
    local dir="$1"
    if [ -z "$dir" ]; then
        echo "dotfile: registerLibrary: path not specified" >&2
        return 1
    fi
    if [ ! -d "$dir" ]; then
        echo "dotfile: registerLibrary: $dir does not exist" >&2
        return 1
    fi
    export LD_LIBRARY_PATH="$dir:$LD_LIBRARY_PATH"
}

# registerPathAndLibrary <dir>
# Registers <dir>/bin to PATH and <dir>/lib to LD_LIBRARY_PATH.
registerPathAndLibrary() {
    local dir="$1"
    registerPath "$dir/bin" || return 1
    registerLibrary "$dir/lib" || return 1
}

_uniqueify_path_bash() {
    local env_var_name="$1"
    local old_ifs="$IFS" path path_array=()
    IFS=':' read -ra path_array <<< "${!env_var_name}"
    IFS="$old_ifs"

    local -A seen=()
    local unique=()
    for path in "${path_array[@]}"; do
        if [ -z "${seen[$path]:-}" ]; then
            seen[$path]=1
            unique+=("$path")
        fi
    done
    local IFS=':'
    echo "${unique[*]}"
}

# shellcheck disable=SC2296 # zsh-only parameter expansion, never parsed by bash at runtime
_uniqueify_path_zsh() {
    local env_var_name="$1"
    local old_ifs="$IFS" path
    IFS=':'
    local path_array=("${(@s/:/)${(P)env_var_name}}")
    IFS="$old_ifs"

    typeset -A seen
    local unique=()
    for path in "${path_array[@]}"; do
        if [ -z "${seen[$path]:-}" ]; then
            seen[$path]=1
            unique+=("$path")
        fi
    done
    local IFS=':'
    echo "${unique[*]}"
}

# uniqueify_path <env-var-name>
# Prints <env-var-name>'s colon-separated value with duplicates removed.
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
# Dedupes PATH in place.
uniqueify_PATH() {
    PATH="$(uniqueify_path PATH)"
    export PATH
}

# uniqueify_LD_LIBRARY_PATH
# Dedupes LD_LIBRARY_PATH in place.
uniqueify_LD_LIBRARY_PATH() {
    LD_LIBRARY_PATH="$(uniqueify_path LD_LIBRARY_PATH)"
    export LD_LIBRARY_PATH
}

# env_self_update
# Fast-forward pulls this dotfile repo in place; refuses on a dirty working tree.
env_self_update() {
    if [ -z "$DOTFILE_ROOT" ]; then
        echo "dotfile: env_self_update: DOTFILE_ROOT not set" >&2
        return 1
    fi
    if [ -n "$(git -C "$DOTFILE_ROOT" status --porcelain)" ]; then
        echo "dotfile: env_self_update: working tree not clean, aborting" >&2
        return 1
    fi
    git -C "$DOTFILE_ROOT" pull --ff-only
}
