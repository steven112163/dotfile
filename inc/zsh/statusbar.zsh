#!/usr/bin/env zsh
# prettify PROMPT in zsh

setopt PROMPT_SUBST

function git_ps1() {
    # gitcb runs faster than __git_ps1
    local name=`git branch 2> /dev/null | grep '*' 2> /dev/null | cut -d' ' -f2-`
    if [ -n "$name" ]; then
        echo "($name)"
    else
        echo ""
    fi
}

function prompt_setup() {
    local user="%F{red}%n%f"
    local host="%F{yellow}%m%f"
    local rpwd="%F{green}%~%f"
    local datetime="%F{magenta}[%D{%H:%M:%S} %D{%Y/%m/%d}]%f"
    local at="%F{white}@%f"
    local sh_in_use="%F{blue}(zsh)%f"

    PROMPT="${user}${at}${host}:${rpwd} %F{cyan}\$(git_ps1)%f ${datetime} ${sh_in_use}
$ "
}
prompt_setup
