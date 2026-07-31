#!/bin/bash
# Installs external tooling this repo's vim/tmux config depends on

is_vim_plug_installed() {
    local root; root="$(resolve_root)" || return 1
    [ -s "$root/.vim/autoload/plug.vim" ]
}

is_tmux_tpm_installed() {
    local root; root="$(resolve_root)" || return 1
    [ -f "$root/.tmux/plugins/tpm/tpm" ]
}

install_vim_plug() {
    local root; root="$(resolve_root)" || return 1
    local dest="$root/.vim/autoload/plug.vim"
    if is_vim_plug_installed; then
        echo "dotfile: vim-plug already installed at $dest"
        return 0
    fi

    local dest_dir; dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"
    local tmp
    tmp="$(mktemp -p "$dest_dir")"
    if ! curl -fLo "$tmp" https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; then
        echo "dotfile: failed to download vim-plug" >&2
        rm -f "$tmp"
        return 1
    fi
    if ! mv "$tmp" "$dest"; then
        echo "dotfile: failed to move vim-plug into place at $dest" >&2
        rm -f "$tmp"
        return 1
    fi
    echo "dotfile: installed vim-plug to $dest"
}

install_tmux_tpm() {
    local root; root="$(resolve_root)" || return 1
    local dest="$root/.tmux/plugins/tpm"
    if is_tmux_tpm_installed; then
        echo "dotfile: tmux TPM already installed at $dest"
        return 0
    fi

    local dest_dir; dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"
    local tmp
    tmp="$(mktemp -d -p "$dest_dir")"
    if ! git clone --depth 1 https://github.com/tmux-plugins/tpm "$tmp"; then
        echo "dotfile: failed to clone tmux TPM" >&2
        rm -rf "$tmp"
        return 1
    fi

    local backup=""
    if [ -e "$dest" ]; then
        backup="$(mktemp -u -p "$dest_dir" "$(basename "$dest").bak.XXXXXX")"
        if ! mv "$dest" "$backup"; then
            echo "dotfile: failed to back up $dest" >&2
            rm -rf "$tmp"
            return 1
        fi
    fi
    if mv "$tmp" "$dest"; then
        [ -n "$backup" ] && rm -rf "$backup"
        echo "dotfile: installed tmux TPM to $dest"
    else
        echo "dotfile: failed to move tmux TPM into place at $dest" >&2
        [ -n "$backup" ] && mv "$backup" "$dest"
        rm -rf "$tmp"
        return 1
    fi
}
