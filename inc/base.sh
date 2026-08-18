#!/bin/bash
# Resolves DOTFILE_ROOT and SHELL_NAME; the zsh branch below is only live when
# this file is sourced from a zsh startup file (bash never evaluates it).

if [ -n "$ZSH_VERSION" ]; then
    DOTFILE_ROOT="$(cd "$(dirname "${(%):-%N}")/.." && pwd)"
    SHELL_NAME=zsh
else
    DOTFILE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    SHELL_NAME=bash
fi

# Only catches an outright cd failure (empty DOTFILE_ROOT); a source path that
# resolves to the wrong-but-non-empty directory is not detected here.
if [ -z "$DOTFILE_ROOT" ]; then
    echo "dotfile: failed to resolve DOTFILE_ROOT" >&2
    return 1
fi

export DOTFILE_ROOT SHELL_NAME

# Shell-agnostic inc/ files sourced by both seeds/bashrc and seeds/zshrc; the
# single list both loop over, so it can't drift between the two entry points.
# venv must precede uv: uv.sh's generate_uv_venv_aliases calls venv.sh's
# _generate_so_aliases. Not exported: arrays aren't exportable, and
# seeds/bashrc and seeds/zshrc source this file into their own shell anyway.
# shellcheck disable=SC2034 # used by seeds/bashrc and seeds/zshrc after sourcing this file
DOTFILE_SHARED_INC=(git-aliases history docker venv uv env)
