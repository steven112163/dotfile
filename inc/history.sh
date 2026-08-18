#!/bin/bash
# Per-tmux-pane shell history with larger history size

_configure_bash_history() {
    if [ -n "$TMUX_PANE" ]; then
        export HISTFILE="$HOME/.bash_history_${TMUX_PANE#\%}"
    fi
    shopt -s histappend
    export HISTSIZE=100000
    export HISTFILESIZE=200000
}

_configure_zsh_history() {
    if [ -n "$TMUX_PANE" ]; then
        export HISTFILE="$HOME/.zsh_history_${TMUX_PANE#\%}"
    fi
    unsetopt share_history
    setopt APPEND_HISTORY
    export HISTSIZE=100000
    export SAVEHIST=200000
}

if [ -n "$BASH_VERSION" ]; then
    _configure_bash_history
elif [ -n "$ZSH_VERSION" ]; then
    _configure_zsh_history
fi
