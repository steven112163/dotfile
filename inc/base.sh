#!/usr/bin/env sh
# Shell-agnostic base: resolves DOTFILE_ROOT and SHELL_NAME for bash and zsh

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
