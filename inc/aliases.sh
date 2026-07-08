#!/bin/bash
# Aliases

# Common aliases
alias al='alias'
alias aliasrc="vim \"$DOTFILE_ROOT/inc/aliases.sh\""

# Add common parameter
alias mv='mv -i'
alias cp='cp -r'
alias scp='scp -r'
alias wget='wget -c'
alias tree='tree -C'
alias ls='ls --color'
alias grep='grep --color'
alias du1='sudo du -h --max-depth 1'
alias dus='du -sh'

# ls aliases
alias l='ls -lCF'
alias l.='ls -ld .*'
alias la='ls -A'
alias ll='ls -l'
alias lh='ls -lh'

# History aliases
alias hi='history'
alias hig='history | grep'

# kill aliases
alias ka9='killall -9'
alias k9='kill -9'

# rm aliases
alias rm-rf='rm -rf'

# rc aliases
alias so="source \"$HOME/.${SHELL_NAME}rc\""
alias so.tmux="tmux source \"$HOME/.tmux.conf\""
alias shrc="vim \"$HOME/.${SHELL_NAME}rc\""
alias vimrc="vim \"$HOME/.vimrc\""
alias gvimrc="gvim \"$HOME/.gvimrc\""
alias tmuxrc="vim \"$HOME/.tmux.conf\""

# python aliases
alias py=python
alias py3=python3

# tmux aliases
alias t='tmux'
alias tl='tmux ls'
alias tn='tmux new -s'
alias ta='tmux attach'
alias tat='tmux attach -t'
