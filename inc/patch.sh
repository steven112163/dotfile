#!/bin/bash
# Idempotent, atomic rc-file patching: append/remove the dotfile source block

DOTFILE_MARKER_BEGIN="dotfile: BEGIN managed block"
DOTFILE_MARKER_END="dotfile: END managed block"

# get_line_number <pattern> <file>
# First matching line number of <pattern> in <file>; empty if not found.
# Never fails the caller under `set -e -o pipefail`, even when <pattern> is
# absent (grep's exit 1 would otherwise propagate through the pipeline).
get_line_number() {
    local pattern="$1" file="$2"
    grep -nF -- "$pattern" "$file" 2>/dev/null | head -1 | cut -d: -f1 || true
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

# _marker_state <file>
# Prints "unpatched" (no markers), "patched" (well-formed BEGIN..END block),
# or "corrupt" (BEGIN without a matching END, or out of order) — a corrupt
# file is refused rather than silently treated as patched or unpatched.
_marker_state() {
    local file="$1" begin end
    begin="$(get_line_number "$DOTFILE_MARKER_BEGIN" "$file")"
    end="$(get_line_number "$DOTFILE_MARKER_END" "$file")"
    if [ -z "$begin" ] && [ -z "$end" ]; then
        echo "unpatched"
    elif [ -n "$begin" ] && [ -n "$end" ] && [ "$end" -gt "$begin" ]; then
        echo "patched"
    else
        echo "corrupt"
    fi
}

# is_patched <file>
# True if <file> has a well-formed dotfile-managed block.
is_patched() {
    [ "$(_marker_state "$1")" = "patched" ]
}

_backup_file() {
    local file="$1"
    [ -f "$file" ] || return 0
    cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S).$$"
}

# _patch_block <file> <comment-char> <content> [validate-shell]
# Idempotently appends a BEGIN/END-marked block to <file>, wrapping <content>
# with <comment-char>-prefixed markers. If <validate-shell> (bash|zsh) is
# given, the candidate file is syntax-checked with `<validate-shell> -n`
# before the atomic mv. Preserves <file>'s original permission bits (mktemp
# defaults to 600, which would otherwise silently tighten every patched rc
# file). Honors DRY_RUN=1: prints a diff and writes nothing.
_patch_block() {
    local file="$1" comment="$2" content="$3" validate_shell="${4:-}"

    case "$(_marker_state "$file")" in
        patched)
            echo "dotfile: $file already patched, skipping"
            return 0
            ;;
        corrupt)
            echo "dotfile: $file has a malformed dotfile block (BEGIN without a matching END), refusing to patch" >&2
            return 1
            ;;
    esac

    mkdir -p "$(dirname "$file")"

    local tmp
    tmp="$(mktemp)"
    [ -f "$file" ] && cat "$file" > "$tmp"
    {
        echo ""
        echo "$comment $DOTFILE_MARKER_BEGIN"
        printf '%s\n' "$content"
        echo "$comment $DOTFILE_MARKER_END"
    } >> "$tmp"

    if [ -n "$validate_shell" ] && ! "$validate_shell" -n "$tmp"; then
        echo "dotfile: patched $file failed syntax check, aborting" >&2
        rm -f "$tmp"
        return 1
    fi

    [ -f "$file" ] && chmod --reference="$file" "$tmp"

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
# (and the original permission bits) untouched. Honors DRY_RUN=1: prints the
# block that would be removed.
_unpatch_block() {
    local file="$1"

    case "$(_marker_state "$file")" in
        unpatched)
            echo "dotfile: $file not patched, skipping"
            return 0
            ;;
        corrupt)
            echo "dotfile: $file has a malformed dotfile block (BEGIN without a matching END), refusing to unpatch" >&2
            return 1
            ;;
    esac

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
    chmod --reference="$file" "$tmp"
    mv "$tmp" "$file"
    echo "dotfile: unpatched $file"
}

patch_shell_rc() {
    local shell="$1"
    local rc; rc="$(get_shell_rc_path "$shell")" || return 1
    local seed="$DOTFILE_ROOT/seeds/${shell}rc"
    _patch_block "$rc" "#" "source \"$seed\"" "$shell"
}

patch_vim_rc() {
    local root="${TARGET_ROOT:-$HOME}"
    local rc="$root/.vimrc"
    local content
    content="$(printf "execute 'source ' . fnameescape('%s')\n" \
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
