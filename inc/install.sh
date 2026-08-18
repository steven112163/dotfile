#!/bin/bash
# Installs external tooling this repo's vim/tmux config depends on

# is_vim_plug_installed
# True if vim-plug's autoload script is already present.
is_vim_plug_installed() {
    local root; root="$(resolve_root)" || return 1
    [ -s "$root/.vim/autoload/plug.vim" ]
}

# is_tmux_tpm_installed
# True if tmux TPM's entry script is already present.
is_tmux_tpm_installed() {
    local root; root="$(resolve_root)" || return 1
    [ -f "$root/.tmux/plugins/tpm/tpm" ]
}

# install_vim_plug
# Downloads vim-plug's autoload script if not already installed.
install_vim_plug() {
    local root; root="$(resolve_root)" || return 1
    local dest="$root/.vim/autoload/plug.vim"
    if is_vim_plug_installed; then
        echo "dotfile: vim-plug already installed at $dest"
        return 0
    fi

    local dest_dir; dest_dir="$(dirname "$dest")"
    if ! mkdir -p "$dest_dir"; then
        echo "dotfile: failed to create directory $dest_dir" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp -p "$dest_dir")" || {
        echo "dotfile: failed to create temp file in $dest_dir" >&2
        return 1
    }
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

# install_tmux_tpm
# Clones tmux TPM if not already installed; backs up and restores any
# existing $dest on failure.
install_tmux_tpm() {
    local root; root="$(resolve_root)" || return 1
    local dest="$root/.tmux/plugins/tpm"
    if is_tmux_tpm_installed; then
        echo "dotfile: tmux TPM already installed at $dest"
        return 0
    fi

    local dest_dir; dest_dir="$(dirname "$dest")"
    if ! mkdir -p "$dest_dir"; then
        echo "dotfile: failed to create directory $dest_dir" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp -d -p "$dest_dir")" || {
        echo "dotfile: failed to create temp directory in $dest_dir" >&2
        return 1
    }
    if ! HOME="$root" XDG_CONFIG_HOME="$root/.config" GIT_CONFIG_GLOBAL="$root/.gitconfig" \
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$tmp"; then
        echo "dotfile: failed to clone tmux TPM" >&2
        rm -rf "$tmp"
        return 1
    fi

    # backup_dir is a real mktemp -d reservation (not a generated name), so
    # moving $dest into it as a child can't race with another process the way
    # renaming to a pre-generated sibling name could.
    local backup_dir="" backup_dest=""
    if [ -e "$dest" ]; then
        backup_dir="$(mktemp -d -p "$dest_dir")" || {
            echo "dotfile: failed to create backup directory in $dest_dir" >&2
            rm -rf "$tmp"
            return 1
        }
        backup_dest="$backup_dir/$(basename "$dest")"
        if ! mv "$dest" "$backup_dest"; then
            echo "dotfile: failed to back up $dest" >&2
            rm -rf "$tmp" "$backup_dir"
            return 1
        fi
    fi
    if mv "$tmp" "$dest"; then
        [ -n "$backup_dir" ] && rm -rf "$backup_dir"
        echo "dotfile: installed tmux TPM to $dest"
    else
        echo "dotfile: failed to move tmux TPM into place at $dest" >&2
        # If the restore also fails, do NOT rm -rf the backup: it's the user's
        # only remaining copy of their original TPM install.
        if [ -n "$backup_dir" ] && ! mv "$backup_dest" "$dest"; then
            echo "dotfile: failed to restore backup, original preserved at $backup_dest" >&2
            rm -rf "$tmp"
            return 1
        fi
        rm -rf "$tmp" "$backup_dir"
        return 1
    fi
}
