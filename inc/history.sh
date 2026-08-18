#!/bin/bash
# Per-tmux-pane shell history with larger history size

_history_size=100000
_history_file_size=200000

_configure_bash_history() {
    if [ -n "$TMUX_PANE" ]; then
        # tmux pane IDs look like "%3"; strip the leading % for the filename.
        export HISTFILE="$HOME/.bash_history_${TMUX_PANE#\%}"
    fi
    shopt -s histappend
    export HISTSIZE="$_history_size"
    export HISTFILESIZE="$_history_file_size"
}

_configure_zsh_history() {
    if [ -n "$TMUX_PANE" ]; then
        # tmux pane IDs look like "%3"; strip the leading % for the filename.
        export HISTFILE="$HOME/.zsh_history_${TMUX_PANE#\%}"
    fi
    unsetopt SHARE_HISTORY
    setopt APPEND_HISTORY
    export HISTSIZE="$_history_size"
    export SAVEHIST="$_history_file_size"
}

if [ -n "$BASH_VERSION" ]; then
    _configure_bash_history
elif [ -n "$ZSH_VERSION" ]; then
    _configure_zsh_history
fi

unset _history_size _history_file_size
