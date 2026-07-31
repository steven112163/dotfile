#!/bin/bash
# Idempotent, atomic rc-file patching: append/remove the dotfile source block
# Uses GNU coreutils (`chmod --reference`, `mktemp -p`); this repo targets Linux only.

DOTFILE_MARKER_BEGIN="dotfile: BEGIN managed block"
DOTFILE_MARKER_END="dotfile: END managed block"

# resolve_root
# Prints $TARGET_ROOT or $HOME; errors on an explicitly-empty $TARGET_ROOT
# instead of silently falling back (${VAR:-default} defaults on empty too).
resolve_root() {
    if [ "${TARGET_ROOT+set}" = set ] && [ -z "$TARGET_ROOT" ]; then
        echo "dotfile: TARGET_ROOT is set but empty, refusing to fall back to \$HOME" >&2
        return 1
    fi
    echo "${TARGET_ROOT:-$HOME}"
}

# get_line_number <marker-text> <file>
# Line number of the generated "<comment-char> <marker-text>" line, empty if
# absent; `|| true` keeps a no-match grep from tripping `set -e -o pipefail`.
get_line_number() {
    local pattern="$1" file="$2"
    grep -nE -- "^. ${pattern}\$" "$file" 2>/dev/null | head -1 | cut -d: -f1 || true
}

# get_shell_rc_path <bash|zsh>
get_shell_rc_path() {
    local root; root="$(resolve_root)" || return 1
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
# Prints "unpatched", "patched" (exactly one well-formed BEGIN..END pair),
# or "corrupt" (missing/duplicate/out-of-order markers).
_marker_state() {
    local file="$1" begin end begin_count end_count
    begin="$(get_line_number "$DOTFILE_MARKER_BEGIN" "$file")"
    end="$(get_line_number "$DOTFILE_MARKER_END" "$file")"
    begin_count="$(grep -cE -- "^. ${DOTFILE_MARKER_BEGIN}\$" "$file" 2>/dev/null)" || begin_count=0
    end_count="$(grep -cE -- "^. ${DOTFILE_MARKER_END}\$" "$file" 2>/dev/null)" || end_count=0
    if [ -z "$begin" ] && [ -z "$end" ]; then
        echo "unpatched"
    elif [ "$begin_count" -eq 1 ] && [ "$end_count" -eq 1 ] && [ "$end" -gt "$begin" ]; then
        echo "patched"
    else
        echo "corrupt"
    fi
}

_backup_file() {
    local file="$1"
    [ -f "$file" ] || return 0
    if ! cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S).$$"; then
        echo "dotfile: failed to back up $file" >&2
        return 1
    fi
}

# _dquote_escape <string>
# Escapes \, ", $, ` for embedding in a double-quoted shell/tmux string.
_dquote_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//\$/\\\$}"
    s="${s//\`/\\\`}"
    printf '%s' "$s"
}

# _vim_squote_escape <string>
# Doubles embedded ' for embedding in a Vim single-quoted string literal
# (fnameescape() escapes filename specials but not the surrounding quote).
_vim_squote_escape() {
    printf '%s' "${1//\'/\'\'}"
}

# _patch_block <file> <comment-char> <content> [validate-shell]
# Idempotently appends a BEGIN/END-marked block, syntax-checked with
# <validate-shell> -n if given. Preserves permission bits, writes the temp
# file alongside <file> for an atomic same-filesystem mv. DRY_RUN=1: diffs
# and writes nothing, not even the target directory.
_patch_block() {
    local file="$1" comment="$2" content="$3" validate_shell="${4:-}"

    case "$(_marker_state "$file")" in
        patched)
            echo "dotfile: $file already patched, skipping"
            return 0
            ;;
        corrupt)
            echo "dotfile: $file has a malformed dotfile block (missing, duplicate, or out-of-order markers), refusing to patch" >&2
            return 1
            ;;
    esac

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

    if [ "${DRY_RUN:-0}" = "1" ]; then
        local diff_src="$file"
        [ -f "$diff_src" ] || diff_src=/dev/null
        local diff_status=0
        diff -u "$diff_src" "$tmp" || diff_status=$?
        rm -f "$tmp"
        if [ "$diff_status" -gt 1 ]; then
            echo "dotfile: diff failed while previewing $file (exit $diff_status)" >&2
            return "$diff_status"
        fi
        return 0
    fi

    mkdir -p "$(dirname "$file")"
    local final_tmp
    final_tmp="$(mktemp -p "$(dirname "$file")")"
    cat "$tmp" > "$final_tmp"
    rm -f "$tmp"
    [ -f "$file" ] && chmod --reference="$file" "$final_tmp"

    _backup_file "$file" || { rm -f "$final_tmp"; return 1; }
    if ! mv "$final_tmp" "$file"; then
        echo "dotfile: failed to move patched content into $file" >&2
        rm -f "$final_tmp"
        return 1
    fi
    echo "dotfile: patched $file"
}

# _unpatch_block <file>
# Removes the BEGIN/END block, preserving everything else. DRY_RUN=1: prints
# the block that would be removed.
_unpatch_block() {
    local file="$1"

    case "$(_marker_state "$file")" in
        unpatched)
            echo "dotfile: $file not patched, skipping"
            return 0
            ;;
        corrupt)
            echo "dotfile: $file has a malformed dotfile block (missing, duplicate, or out-of-order markers), refusing to unpatch" >&2
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

    _backup_file "$file" || return 1
    local tmp
    tmp="$(mktemp -p "$(dirname "$file")")"
    sed "${begin},${end}d" "$file" > "$tmp"
    chmod --reference="$file" "$tmp"
    if ! mv "$tmp" "$file"; then
        echo "dotfile: failed to move unpatched content into $file" >&2
        rm -f "$tmp"
        return 1
    fi
    echo "dotfile: unpatched $file"
}

patch_shell_rc() {
    local shell="$1"
    local rc; rc="$(get_shell_rc_path "$shell")" || return 1
    local seed="$DOTFILE_ROOT/seeds/${shell}rc"
    _patch_block "$rc" "#" "source \"$(_dquote_escape "$seed")\"" "$shell"
}

patch_vim_rc() {
    local root; root="$(resolve_root)" || return 1
    local rc="$root/.vimrc"
    local paths=(
        "$DOTFILE_ROOT/.vim/plugin/setting.vim"
        "$DOTFILE_ROOT/.vim/plugin/hotkeys.vim"
        "$DOTFILE_ROOT/.vim/plugin/helpers.vim"
        "$DOTFILE_ROOT/.vim/plugin/plug.vim"
    )
    local path
    local escaped=()
    for path in "${paths[@]}"; do
        escaped+=("$(_vim_squote_escape "$path")")
    done
    local content
    content="$(printf "execute 'source ' . fnameescape('%s')\n" "${escaped[@]}")"
    _patch_block "$rc" "\"" "$content"
}

patch_tmux_rc() {
    local root; root="$(resolve_root)" || return 1
    local rc="$root/.tmux.conf"
    _patch_block "$rc" "#" "source-file \"$(_dquote_escape "$DOTFILE_ROOT/.tmux.conf")\""
}

unpatch_shell_rc() {
    local shell="$1"
    local rc; rc="$(get_shell_rc_path "$shell")" || return 1
    _unpatch_block "$rc"
}

unpatch_vim_rc() {
    local root; root="$(resolve_root)" || return 1
    _unpatch_block "$root/.vimrc"
}

unpatch_tmux_rc() {
    local root; root="$(resolve_root)" || return 1
    _unpatch_block "$root/.tmux.conf"
}
