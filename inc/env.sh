#!/bin/bash
# PATH/LD_LIBRARY_PATH registration and dedup helpers, plus self-update

# _require_dir <dir> <label>
# Prints a "<label>: ..." error and fails if <dir> is empty or not a directory.
_require_dir() {
    local dir="$1" label="$2"
    if [ -z "$dir" ]; then
        echo "dotfile: $label: path not specified" >&2
        return 1
    fi
    if [ ! -d "$dir" ]; then
        echo "dotfile: $label: $dir does not exist" >&2
        return 1
    fi
}

# register_path <dir>
# Prepends <dir> to PATH if it exists.
register_path() {
    local dir="$1"
    _require_dir "$dir" register_path || return 1
    PATH="$dir${PATH:+:$PATH}"
    export PATH
}

# register_library <dir>
# Prepends <dir> to LD_LIBRARY_PATH if it exists.
register_library() {
    local dir="$1"
    _require_dir "$dir" register_library || return 1
    LD_LIBRARY_PATH="$dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export LD_LIBRARY_PATH
}

# register_path_and_library <dir>
# Registers <dir>/bin to PATH and <dir>/lib to LD_LIBRARY_PATH.
# Validates both directories before mutating either.
register_path_and_library() {
    local dir="$1"
    _require_dir "$dir/bin" register_path_and_library || return 1
    _require_dir "$dir/lib" register_path_and_library || return 1
    register_path "$dir/bin"
    register_library "$dir/lib"
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

# uniqueify_var <env-var-name>
# Prints <env-var-name>'s colon-separated value with duplicates and empty
# components removed. <env-var-name> must be a valid identifier.
uniqueify_var() {
    local env_var_name="$1"
    if [[ ! $env_var_name =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        echo "dotfile: uniqueify_var: invalid variable name: $env_var_name" >&2
        return 1
    fi
    if [ -n "$ZSH_VERSION" ]; then
        _uniqueify_path_zsh "$env_var_name"
    elif [ -n "$BASH_VERSION" ]; then
        _uniqueify_path_bash "$env_var_name"
    else
        echo "dotfile: uniqueify_var: unsupported shell" >&2
        return 1
    fi
}

# uniqueify_PATH
# Dedupes PATH in place; leaves PATH untouched if the dedup itself fails.
uniqueify_PATH() {
    local new
    new="$(uniqueify_var PATH)" && PATH="$new" && export PATH
}

# uniqueify_LD_LIBRARY_PATH
# Dedupes LD_LIBRARY_PATH in place; leaves it untouched if the dedup fails.
uniqueify_LD_LIBRARY_PATH() {
    local new
    new="$(uniqueify_var LD_LIBRARY_PATH)" && LD_LIBRARY_PATH="$new" && export LD_LIBRARY_PATH
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
    # `status` is a read-only special parameter in zsh (alias for $?); using
    # it as a local name here fails hard under zsh before the || fallback
    # can catch it.
    local git_status_output
    git_status_output="$(git -C "$DOTFILE_ROOT" status --porcelain)" || {
        echo "dotfile: env_self_update: git status failed" >&2
        return 1
    }
    if [ -n "$git_status_output" ]; then
        echo "dotfile: env_self_update: working tree not clean, aborting" >&2
        return 1
    fi
    git -C "$DOTFILE_ROOT" pull --ff-only
}
