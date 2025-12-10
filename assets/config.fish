if status is-interactive
    # Commands to run in interactive sessions can go here
end
set -U fish_greeting ""

# PATH completo - PRECISA VIR ANTES DE TUDO
#set -gx PATH /usr/local/bin /usr/bin /bin /usr/local/sbin /usr/sbin /sbin $HOME/bin $HOME/.local/bin $HOME/flutter/bin

set -gx PATH /usr/local/bin /usr/bin /bin /usr/local/sbin /usr/sbin /sbin $HOME/bin $HOME/.local/bin $HOME/flutter/bin $HOME/.pub-cache/bin /usr/local/flutter/bin/cache/dart-sdk/bin

# FZF (comente se não tiver instalado)
if type -q fzf
    fzf --fish | source
end

# Zoxide (comente se não tiver instalado)
if type -q zoxide
    zoxide init fish | source
end

# Starship prompt
if type -q starship
    starship init fish | source
end

# Mise
if test -f $HOME/.local/bin/mise
    eval "$(~/.local/bin/mise activate fish | source)"
end

# Node options
set -gx NODE_OPTIONS "--max-old-space-size=4096"

# Spacefish config
set SPACEFISH_PROMPT_ADD_NEWLINE false

# FZF config
set -gx FZF_CTRL_T_OPTS "
  --style full
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# Alias do Sistema
alias configFish='sudo nano ~/.config/fish/config.fish'
alias configStarship='sudo nano ~/.config/starship.toml'
alias ls='eza --color=always --git --no-filesize --icons=always --group-directories-first --no-time --no-user --no-permissions'
alias cat='batcat --style=plain --paging=never'
alias cd='z'
alias l='ls -la'
alias conect-mv='ssh -i ~/.ssh/id_ed25519 ubuntu@137.131.195.115'

# Alias Git
alias gcd='git checkout develop'
alias pull='git pull'
alias push='git push'
alias gcb='git checkout -b'
alias checkout='git checkout'
alias clone='git clone'

