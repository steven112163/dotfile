#!/bin/bash
# Applies git and vim-plug configuration for this environment

# _git_config_global <root> <args...>
# Runs `git config --global <args...>` fully isolated from the real user
# environment. Git resolves the global config file from $GIT_CONFIG_GLOBAL,
# then $HOME/.gitconfig, then $XDG_CONFIG_HOME/git/config, in that order — all
# three must be overridden, or a value inherited from the real environment
# (e.g. a corporate git wrapper exporting $GIT_CONFIG_GLOBAL) can still
# redirect --target-root writes to the real git config.
_git_config_global() {
    local root="$1"; shift
    HOME="$root" XDG_CONFIG_HOME="$root/.config" GIT_CONFIG_GLOBAL="$root/.gitconfig" \
        git config --global "$@"
}

# config_git_vim_diff
# Configures `git vimdiff` (aliased to difftool) to use vimdiff, unprompted.
config_git_vim_diff() {
    local root; root="$(resolve_root)" || return 1
    _git_config_global "$root" diff.tool vimdiff &&
    _git_config_global "$root" difftool.prompt false &&
    _git_config_global "$root" alias.vimdiff difftool
}

# config_git_core_editor
# Sets git's core.editor to vim.
config_git_core_editor() {
    local root; root="$(resolve_root)" || return 1
    _git_config_global "$root" core.editor vim
}

# config_git_credential_cache
# Caches git credential helper entries for 100 days.
config_git_credential_cache() {
    local root; root="$(resolve_root)" || return 1
    # 8640000s = 100 days
    _git_config_global "$root" credential.helper "cache --timeout 8640000"
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
