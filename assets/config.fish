
fzf --fish | source
zoxide init fish | source
set SPACEFISH_PROMPT_ADD_NEWLINE false
starship init fish | source




# Alias do Sistema
alias configFish='sudo nano ~/.config/fish/config.fish'
alias configStarship='sudo nano ~/.config/starship.toml'
alias ls='eza --color=always --git --no-filesize --icons=always --group-directories-first --no-time --no-user --no-permissions'
alias cat='batcat --style=plain --paging=never'
alias cd='z'
alias l='ls -la'

# Alias Git
alias gcd='git checkout develop'
alias pull='git pull'
alias push='git push'
alias gcb='git checkout -b'
alias checkout='git checkout'
alias clone='git clone'



export FZF_CTRL_T_OPTS="
  --style full
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
