#!/bin/bash

export IGNOREEOF=99999999
set -o noclobber
set completion-ignore-case On
source $HOME/.git-completion.sh
umask 002
export EDITOR=vim

if [ "$PS1" ]; then             # interactive shell
    # make colorful prompt, including pwd, host and git repo branch
    CYAN="\[\033[0;36m\]"
    GRAY="\[\033[0;37m\]"
    BLACK="\[\033[0;30m\]"
    BLUE="\[\033[0;34m\]"
    RED="\[\033[0;31m\]"
    GREEN="\[\033[0;32m\]"
    PURPLE="\[\033[0;35m\]"
    BROWN="\[\033[0;33m\]"
    NONE="\[\e[m\]"
    if [ -d '/vagrant/' ]; then
        # purple on a vagrant vm
        export PS1=$PURPLE'\u@\h '$BROWN'\w'$CYAN'$(__git_ps1 " (%s)")'$BROWN'>'$NONE" "
        cd /vagrant
    else 
        # red on the workstation
        export PS1=$RED'\u@\h '$BROWN'\w'$CYAN'$(__git_ps1 " (%s)")'$BROWN'>'$NONE" "
    fi
fi

if [ `uname` = "Darwin" ]; then
    export CLICOLOR=1
    export PATH=$HOME/bin:/opt/local/bin:/opt/local/sbin:$PATH
    export MANPATH=/opt/local/share/man:$MANPATH
else
    alias ls="ls --color"
fi

alias rm='rm -i'
alias mv='mv -i'
alias grep='grep --color=tty'
alias less='less -R'
alias gm='genome model'
alias gml='genome model list'
alias gmb='genome model build'
alias gmba='genome model build abandon'
alias gmbl='genome model build list'
alias gmbs='genome model build start'
alias gmbv='genome model build view'

#alias cd="pushd >/dev/null";
#alias bd="popd >/dev/null";

#alias ta="tmux -S $HOME/mytmux attach-session"
#alias tn="tmux -S $HOME/mytmux new-session"

if [ -e '/etc/genome.conf' ]; then
    source /etc/genome.conf
fi

( echo $PATH | grep $HOME/bin >/dev/null ) || export PATH=$HOME/bin:$PATH

