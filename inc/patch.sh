#!/bin/bash
# Idempotent, atomic rc-file patching: append/remove the dotfile source block

DOTFILE_MARKER_BEGIN="dotfile: BEGIN managed block"
DOTFILE_MARKER_END="dotfile: END managed block"

# ensure_line_in_file <line> <file>
# Appends <line> to <file> if not already present. Idempotent single-line insert.
ensure_line_in_file() {
    local line="$1" file="$2"
    grep -qF -- "$line" "$file" 2>/dev/null || printf '%s\n' "$line" >> "$file"
}

# get_line_number <pattern> <file>
# First matching line number of <pattern> in <file>; empty if not found.
get_line_number() {
    local pattern="$1" file="$2"
    grep -nF -- "$pattern" "$file" 2>/dev/null | head -1 | cut -d: -f1
}

# get_shell_rc_path <bash|zsh>
get_shell_rc_path() {
    local root="${TARGET_ROOT:-$HOME}"
    case "$1" in
        bash) echo "$root/.bashrc" ;;
        zsh) echo "$root/.zshrc" ;;
        *)
            echo "dotfile: get_shell_rc_path: unsupported shell '$1'" >&2
            return 1
            ;;
    esac
}

_backup_file() {
    local file="$1"
    [ -f "$file" ] || return 0
    cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
}

# _patch_block <file> <comment-char> <content> [validate-cmd]
# Idempotently appends a BEGIN/END-marked block to <file>, wrapping <content>
# with <comment-char>-prefixed markers. If <validate-cmd> is given, it's run
# against the candidate file before the atomic mv (used for bash -n/zsh -n).
# Honors DRY_RUN=1: prints a diff and writes nothing.
_patch_block() {
    local file="$1" comment="$2" content="$3" validate_cmd="${4:-}"

    if grep -qF -- "$DOTFILE_MARKER_BEGIN" "$file" 2>/dev/null; then
        echo "dotfile: $file already patched, skipping"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"
    [ -f "$file" ] && cat "$file" > "$tmp"
    {
        echo ""
        echo "$comment $DOTFILE_MARKER_BEGIN"
        printf '%s\n' "$content"
        echo "$comment $DOTFILE_MARKER_END"
    } >> "$tmp"

    if [ -n "$validate_cmd" ] && ! $validate_cmd "$tmp"; then
        echo "dotfile: patched $file failed syntax check, aborting" >&2
        rm -f "$tmp"
        return 1
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        local diff_src="$file"
        [ -f "$diff_src" ] || diff_src=/dev/null
        diff -u "$diff_src" "$tmp" || true
        rm -f "$tmp"
        return 0
    fi

    _backup_file "$file"
    mv "$tmp" "$file"
    echo "dotfile: patched $file"
}

# _unpatch_block <file>
# Removes the BEGIN/END-marked block from <file>, leaving everything else
# untouched. Honors DRY_RUN=1: prints the block that would be removed.
_unpatch_block() {
    local file="$1"

    if ! grep -qF -- "$DOTFILE_MARKER_BEGIN" "$file" 2>/dev/null; then
        echo "dotfile: $file not patched, skipping"
        return 0
    fi

    local begin end
    begin="$(get_line_number "$DOTFILE_MARKER_BEGIN" "$file")"
    end="$(get_line_number "$DOTFILE_MARKER_END" "$file")"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        sed -n "${begin},${end}p" "$file"
        return 0
    fi

    _backup_file "$file"
    local tmp
    tmp="$(mktemp)"
    sed "${begin},${end}d" "$file" > "$tmp"
    mv "$tmp" "$file"
    echo "dotfile: unpatched $file"
}

patch_shell_rc() {
    local shell="$1"
    local rc; rc="$(get_shell_rc_path "$shell")" || return 1
    local seed="$DOTFILE_ROOT/seeds/${shell}rc"
    local validate="bash -n"
    [ "$shell" = zsh ] && validate="zsh -n"
    _patch_block "$rc" "#" "source \"$seed\"" "$validate"
}

patch_vim_rc() {
    local root="${TARGET_ROOT:-$HOME}"
    local rc="$root/.vimrc"
    local content
    content="$(printf 'source %s\n' \
        "$DOTFILE_ROOT/.vim/plugin/setting.vim" \
        "$DOTFILE_ROOT/.vim/plugin/hotkeys.vim" \
        "$DOTFILE_ROOT/.vim/plugin/helpers.vim" \
        "$DOTFILE_ROOT/.vim/plugin/plug.vim")"
    _patch_block "$rc" "\"" "$content"
}

patch_tmux_rc() {
    local root="${TARGET_ROOT:-$HOME}"
    local rc="$root/.tmux.conf"
    _patch_block "$rc" "#" "source-file \"$DOTFILE_ROOT/.tmux.conf\""
}

unpatch_shell_rc() {
    local shell="$1"
    local rc; rc="$(get_shell_rc_path "$shell")" || return 1
    _unpatch_block "$rc"
}

unpatch_vim_rc() {
    local root="${TARGET_ROOT:-$HOME}"
    _unpatch_block "$root/.vimrc"
}

unpatch_tmux_rc() {
    local root="${TARGET_ROOT:-$HOME}"
    _unpatch_block "$root/.tmux.conf"
}
