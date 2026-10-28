# ~/.zshrc - configuración interactiva de Zsh para Guix System
# Los archivos .zprofile/.bash_profile los instala Guix desde /etc/skel.

HISTFILE="$HOME/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
setopt appendhistory sharehistory incappendhistory extendedhistory

mkdir -p "$HOME/.cache/zsh"
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
setopt autocd extendedglob nomatch interactivecomments

PROMPT='%F{cyan}%n%f@%F{green}%m%f %F{blue}%~%f %# '
RPROMPT='%F{242}%D{%H:%M}%f'

alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias egrep='grep -E'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gc='git commit'
alias gl='git log --oneline --graph --decorate'
alias update='sudo guix pull && sudo guix system reconfigure /run/current-system/etc/config.scm'

export EDITOR=nano
export VISUAL=nano
export PAGER=less
export PATH="$HOME/.guix-profile/bin:$HOME/.local/bin:/run/current-system/profile/bin:/run/current-system/profile/sbin:$PATH"

# Historial compartido entre terminales y ayuda de Guix.
if command -v guix >/dev/null 2>&1; then
  alias guix-shell='guix shell --container --network --preserve=^HOME$'
fi
