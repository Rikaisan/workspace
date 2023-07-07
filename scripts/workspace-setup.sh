PREFIX="[Workspace Setup]"

if !(grep -q ZDOTDIR /etc/zsh/zshenv 2> /dev/null)
then
echo "$PREFIX Didn't find ZDOTDIR, exporting to /etc/zsh/zshenv..."
su root -c "echo \"export ZDOTDIR=~/.config/zsh\" >> /etc/zsh/zshenv"
fi

if !(grep -q stow /etc/zsh/zshenv 2> /dev/null)
then
echo "$PREFIX Didn't find dotcfg alias, exporting to /etc/zsh/zshenv..."
su root -c "echo \"alias dotcfg=\\\"stow -t ~\\\"\" >> /etc/zsh/zshenv"
fi
