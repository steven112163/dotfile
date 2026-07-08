#!/bin/bash
# Settings

source "$DOTFILE_ROOT/inc/aliases.sh"

export PATH="$HOME/bin:$HOME/local/bin:$HOME/.local/bin:$PATH"
export VIM_BIN="$(command -v vim || echo /usr/bin/vim)"
export EDITOR="$VIM_BIN"
export SVN_EDITOR="$EDITOR"
export VISUAL="$VIM_BIN"
export GREP_COLOR="1;33"
export HISTCONTROL=ignoreboth
export TERM=xterm-256color
export LANG=en_US.UTF-8
export LC_ALL=${LANG}
export LC_CTYPE=en_US.UTF-8
