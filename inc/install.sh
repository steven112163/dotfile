#!/bin/bash
# Installs external tooling this repo's vim/tmux config depends on

is_vim_plug_installed() {
    local root="${TARGET_ROOT:-$HOME}"
    [ -f "$root/.vim/autoload/plug.vim" ]
}

is_tmux_tpm_installed() {
    local root="${TARGET_ROOT:-$HOME}"
    [ -f "$root/.tmux/plugins/tpm/tpm" ]
}

install_vim_plug() {
    local root="${TARGET_ROOT:-$HOME}"
    local dest="$root/.vim/autoload/plug.vim"
    if is_vim_plug_installed; then
        echo "dotfile: vim-plug already installed at $dest"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"
    if ! curl -fLo "$tmp" https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; then
        echo "dotfile: failed to download vim-plug" >&2
        rm -f "$tmp"
        return 1
    fi
    mkdir -p "$(dirname "$dest")"
    mv "$tmp" "$dest"
    echo "dotfile: installed vim-plug to $dest"
}

install_tmux_tpm() {
    local root="${TARGET_ROOT:-$HOME}"
    local dest="$root/.tmux/plugins/tpm"
    if is_tmux_tpm_installed; then
        echo "dotfile: tmux TPM already installed at $dest"
        return 0
    fi

    local tmp
    tmp="$(mktemp -d)"
    if ! git clone --depth 1 https://github.com/tmux-plugins/tpm "$tmp"; then
        echo "dotfile: failed to clone tmux TPM" >&2
        rm -rf "$tmp"
        return 1
    fi
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    mv "$tmp" "$dest"
    echo "dotfile: installed tmux TPM to $dest"
}
