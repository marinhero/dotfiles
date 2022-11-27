#------------SHELL CONFIG-------------

set -o vi
set bell-style none

#------------ALIAS------------

alias blog='cd ~/Code/marinhero.github.io'
alias gap='git add --patch'
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
alias zshrc='vim ~/.oh-my-zsh/custom/marin.zsh'


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

#------------ENV-----------------
export HISTTIMEFORMAT="%d/%m/%y %T "
export SUDO_PS1='\[\e[0;31m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[0;31m\]\$ \[\e[m\]\[\e[0;32m\]'

#--------------MAC OS-------------
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias show-hidden='defaults write com.apple.Finder AppleShowAllFiles TRUE'
  alias hide='defaults write com.apple.Finder AppleShowAllFiles FALSE'
fi
