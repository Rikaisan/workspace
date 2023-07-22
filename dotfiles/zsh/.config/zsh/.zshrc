# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt extendedglob nomatch
unsetopt beep
# End of lines configured by zsh-newuser-install

# Load custom aliases
if [[ -e ~/.config/rikai/aliases ]]; then
  source ~/.config/rikai/aliases
fi

eval $(starship init zsh)

if [[ -e ~/.config/zplug/init.zsh ]]; then
  source ~/.config/zplug/init.zsh
  zplug "MichaelAquilina/zsh-auto-notify"
  zplug "MichaelAquilina/zsh-you-should-use"
  zplug 'zplug/zplug', hook-build:'zplug --self-manage'
  zplug load
fi

# Nav
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^[[3~" delete-char

source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
