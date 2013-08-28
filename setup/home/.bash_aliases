#!/bin/bash

export IGNOREEOF=99999999
alias cd="pushd >/dev/null";
alias bd="popd >/dev/null";
set -o noclobber
set completion-ignore-case On
source $HOME/.git-completion.sh
umask 002
export EDITOR=vim

if [ "$PS1" ]; then             # interactive shell
    # make colorful prompt
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
        # purple on the vm
        export PS1=$PURPLE'\u@\h '$BROWN'\w'$CYAN'$(__git_ps1 " (%s)")'$BROWN'>'$NONE" "
        cd /vagrant
    else 
        # red on the workstation
        export PS1=$RED'\u@\h '$BROWN'\w'$CYAN'$(__git_ps1 " (%s)")'$BROWN'>'$NONE" "
    fi
fi

if [ `uname` = "Darwin" ]; then
    echo init paths...
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

if [ -e '/etc/genome.conf' ]; then
    source /etc/genome.conf
fi

( echo $PATH | grep $HOME/bin >/dev/null ) || export PATH=$HOME/bin:$PATH

