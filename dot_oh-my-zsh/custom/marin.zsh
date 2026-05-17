#------------SHELL CONFIG-------------

set -o vi
set bell-style none

#------------FASTFETCH-----------------
if command -v fastfetch &>/dev/null && [[ -z "$ZELLIJ" ]]; then
  fastfetch
fi

#------------BLACK + NORD COLORS (st terminal)--
if [ "$TERM" = "st-256color" ]; then
  # Background/foreground/cursor
  printf '\033]11;#000000\033\\'
  printf '\033]10;#d8dee9\033\\'
  printf '\033]12;#d8dee9\033\\'
  # Normal colors
  printf '\033]4;0;#000000\033\\'
  printf '\033]4;1;#bf616a\033\\'
  printf '\033]4;2;#a3be8c\033\\'
  printf '\033]4;3;#ebcb8b\033\\'
  printf '\033]4;4;#81a1c1\033\\'
  printf '\033]4;5;#b48ead\033\\'
  printf '\033]4;6;#88c0d0\033\\'
  printf '\033]4;7;#e5e9f0\033\\'
  # Bright colors
  printf '\033]4;8;#4c566a\033\\'
  printf '\033]4;9;#bf616a\033\\'
  printf '\033]4;10;#a3be8c\033\\'
  printf '\033]4;11;#ebcb8b\033\\'
  printf '\033]4;12;#81a1c1\033\\'
  printf '\033]4;13;#b48ead\033\\'
  printf '\033]4;14;#8fbcbb\033\\'
  printf '\033]4;15;#eceff4\033\\'
fi

#------------ASDF VERSION MANAGER-----
# asdf v0.16+ shims must be first in PATH so they take priority over system binaries
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)

#------------ALIAS (Shared)------------

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
alias ne='nvim'
alias pom='git pull origin master --rebase'
alias vim='nvim'
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

#------------CLAUDE PIPES--------------
# One-shot Claude Code in print mode. Pipes stdin or takes args.
#   cat file | askc "summarize"
#   git diff | askcc "any regressions?"   # continues last session
#   journalctl -n 200 | askch "what failed?"  # Haiku, cheap/fast
askc()  { claude -p "$@"; }
askcc() { claude -p -c "$@"; }
askch() { claude -p --model claude-haiku-4-5-20251001 "$@"; }

#------------ENV-----------------
export HISTTIMEFORMAT="%d/%m/%y %T "
export SUDO_PS1='\[\e[0;31m\]\u\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[0;31m\]\$ \[\e[m\]\[\e[0;32m\]'

# Per-machine secrets (HF_TOKEN, etc.) — not managed by chezmoi
[[ -f "$HOME/.config/zsh/secrets.zsh" ]] && source "$HOME/.config/zsh/secrets.zsh"
# Termux: point local-llm at the 14B model with a 16K context window.
# Restored on shell start; local-llm reads these on `start chat`.
export LOCAL_LLM_MODEL="$HOME/models/Qwen3-14B-Q4_K_M.gguf"
export LOCAL_LLM_CTX=16384
# Backend default is cpu (safe). To use Adreno OpenCL for ~9.5x prompt
# processing on Q4_0 GGUFs (see ~/.local/bin/local-llm header for setup):
#   export LOCAL_LLM_BACKEND=opencl
#   export LOCAL_LLM_MODEL="$HOME/models/Qwen3-4B-Instruct-2507-Q4_0.gguf"
# 14B + opencl has OOM-killed Termux — close Claude and shrink ctx first.

# Local LLM persona shortcuts (Qwen3-14B @ :8090, temperature pinned to 0.2).
# Templates live in ~/.config/io.datasette.llm/templates/<name>.yaml.
#   brief  "...": terse persona — short, direct answers
#   review "...": coder persona — engineering judgment, code review
#   teach  "...": teacher persona — pedagogical, builds mental models
alias brief='llm -t terse -o temperature 0.2'
alias review='llm -t coder -o temperature 0.2'
alias teach='llm -t teacher -o temperature 0.2'

#--------------MAC OS-------------
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias show-hidden='defaults write com.apple.Finder AppleShowAllFiles TRUE'
  alias hide='defaults write com.apple.Finder AppleShowAllFiles FALSE'
fi
#--------GOTO--------------

goto() {
  repo=$1

  # Re-map blog reop
  if [[ $repo == "blog" ]]
  then
    repo="marinhero.github.io"
  fi

  dir="$HOME/Code/$repo"
  if [ -d "$dir" ]
  then
    cd "$dir"
  else
    gh repo clone "marinhero/$repo" "$dir" && cd "$dir"
  fi
}

#------------MACHINE-SPECIFIC CONFIG------------

#------------FZF-----------------
# Source fzf key-bindings (Ctrl-R history search, Ctrl-T file search, Alt-C cd)
# and completions. Check asdf install first, then platform-specific fallbacks.
_fzf_sourced=0

# asdf-managed fzf
if command -v asdf &>/dev/null; then
  _fzf_asdf_dir="$(asdf where fzf 2>/dev/null)/shell"
  if [[ -d "$_fzf_asdf_dir" ]]; then
    [[ -f "$_fzf_asdf_dir/key-bindings.zsh" ]] && source "$_fzf_asdf_dir/key-bindings.zsh"
    [[ -f "$_fzf_asdf_dir/completion.zsh" ]]   && source "$_fzf_asdf_dir/completion.zsh"
    _fzf_sourced=1
  fi
  unset _fzf_asdf_dir
fi

# Fallback to system install
if (( ! _fzf_sourced )); then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    for fzf_dir in /opt/homebrew/opt/fzf /usr/local/opt/fzf; do
      if [[ -d "$fzf_dir/shell" ]]; then
        [[ -f "$fzf_dir/shell/key-bindings.zsh" ]] && source "$fzf_dir/shell/key-bindings.zsh"
        [[ -f "$fzf_dir/shell/completion.zsh" ]]   && source "$fzf_dir/shell/completion.zsh"
        break
      fi
    done
  else
    [[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && source /usr/share/fzf/shell/key-bindings.zsh
    [[ -f /usr/share/fzf/shell/completion.zsh ]]   && source /usr/share/fzf/shell/completion.zsh
  fi
fi
unset _fzf_sourced
