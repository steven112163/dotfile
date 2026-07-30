#!/bin/bash
# Applies git and vim-plug configuration for this environment

config_git_vim_diff() {
    local root="${TARGET_ROOT:-$HOME}"
    HOME="$root" git config --global diff.tool vimdiff
    HOME="$root" git config --global difftool.prompt false
    HOME="$root" git config --global alias.vimdiff difftool
}

config_git_core_editor() {
    local root="${TARGET_ROOT:-$HOME}"
    HOME="$root" git config --global core.editor vim
}

config_git_cache_timeout() {
    local root="${TARGET_ROOT:-$HOME}"
    # 8640000s = 100 days
    HOME="$root" git config --global credential.helper "cache --timeout 8640000"
}

config_vim_plug() {
    local root="${TARGET_ROOT:-$HOME}"
    # HOME must be overridden too, not just -u: plug#begin('~/.vim/plugged') in
    # .vim/plugin/plug.vim expands `~` via vim's own $HOME, independent of the
    # -u vimrc path — without this, --target-root still writes plugins into the
    # real ~/.vim/plugged.
    HOME="$root" vim -E -s -u "$root/.vimrc" +PlugInstall +qall
}
