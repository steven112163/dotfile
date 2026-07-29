#!/bin/bash
# Installs external tooling this repo's vim/tmux config depends on

install_vim_plug() {
    local root="${TARGET_ROOT:-$HOME}"
    local dest="$root/.vim/autoload/plug.vim"
    if [ -f "$dest" ]; then
        echo "dotfile: vim-plug already installed at $dest"
        return 0
    fi
    curl -fLo "$dest" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "dotfile: installed vim-plug to $dest"
}

install_tmux_tpm() {
    local root="${TARGET_ROOT:-$HOME}"
    local dest="$root/.tmux/plugins/tpm"
    if [ -d "$dest" ]; then
        echo "dotfile: tmux TPM already installed at $dest"
        return 0
    fi
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$dest"
    echo "dotfile: installed tmux TPM to $dest"
}
