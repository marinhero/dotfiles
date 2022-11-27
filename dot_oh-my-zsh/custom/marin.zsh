#------------SHELL CONFIG-------------

set -o vi
set bell-style none
shopt -s histappend

#------------ALIAS------------

alias blog='cd ~/Code/marinhero.github.io'
alias gc='git commit -v'
alias gca='git commit -v --amend'
alias gcm='git checkout master'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gra='git reset --soft HEAD@{1}'
alias gri='git fetch && git rebase -i origin/master'
alias gs='git status'
alias l='ls -l'
alias ne='vim'
alias pom='git pull origin master --rebase'
alias vimrc='vim ~/.vimrc'


#-----------COLORED MAN----------------

man() {
    env \
        LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
        LESS_TERMCAP_md="$(printf "\e[1;31m")" \
        LESS_TERMCAP_me="$(printf "\e[0m")" \
        LESS_TERMCAP_se="$(printf "\e[0m")" \
        LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
        LESS_TERMCAP_ue="$(printf "\e[0m")" \
        LESS_TERMCAP_us="$(printf "\e[1;32m")" \
        man "$@"
}

#-------DIFF-SO-FANCY------------------
git config --global color.ui true

git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "11"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.func       "146 bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"

