#!/bin/bash
# Applies git and vim-plug configuration for this environment

# config_git_vim_diff
# Configures `git vimdiff` (aliased to difftool) to use vimdiff, unprompted.
config_git_vim_diff() {
    local root; root="$(resolve_root)" || return 1
    # XDG_CONFIG_HOME must be overridden too, not just HOME: git falls back to
    # $XDG_CONFIG_HOME/git/config when $HOME/.gitconfig doesn't exist — without
    # this, --target-root can silently write to the real git config instead.
    HOME="$root" XDG_CONFIG_HOME="$root/.config" git config --global diff.tool vimdiff &&
    HOME="$root" XDG_CONFIG_HOME="$root/.config" git config --global difftool.prompt false &&
    HOME="$root" XDG_CONFIG_HOME="$root/.config" git config --global alias.vimdiff difftool
}

# config_git_core_editor
# Sets git's core.editor to vim.
config_git_core_editor() {
    local root; root="$(resolve_root)" || return 1
    HOME="$root" XDG_CONFIG_HOME="$root/.config" git config --global core.editor vim
}

# config_git_credential_cache
# Caches git credential helper entries for 100 days.
config_git_credential_cache() {
    local root; root="$(resolve_root)" || return 1
    # 8640000s = 100 days
    HOME="$root" XDG_CONFIG_HOME="$root/.config" git config --global credential.helper "cache --timeout 8640000"
}

# config_vim_plug
# Runs vim-plug's :PlugInstall against the patched .vimrc.
config_vim_plug() {
    local root; root="$(resolve_root)" || return 1
    # HOME must be overridden too, not just -u: plug#begin('~/.vim/plugged') in
    # .vim/plugin/plug.vim expands `~` via vim's own $HOME, independent of the
    # -u vimrc path — without this, --target-root still writes plugins into the
    # real ~/.vim/plugged.
    HOME="$root" vim -E -s -u "$root/.vimrc" +PlugInstall +qall
}
