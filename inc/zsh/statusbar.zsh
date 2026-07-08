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

user="%F{red}%n%f"
host="%F{yellow}%m%f"
rpwd="%F{green}%~%f"
datetime="%F{magenta}[%D{%H:%M:%S} %D{%Y/%m/%d}]%f"
at="%F{white}@%f"
sh_in_use="%F{blue}(zsh)%f"

PROMPT='${user}${at}${host}:${rpwd} %F{cyan}$(git_ps1)%f ${datetime} ${sh_in_use}
$ '
