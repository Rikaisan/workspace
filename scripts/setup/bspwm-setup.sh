pacman -S --needed - < bspwm.lst

if !(grep -q ZDOTDIR /etc/zsh/zshenv 2> /dev/null)
then
echo "$WARN_PREFIX Didn't find ZDOTDIR, exporting to /etc/zsh/zshenv..."
echo export ZDOTDIR=/home/$USERNAME/.config/zsh >> /etc/zsh/zshenv
fi

if !(grep -q stow /etc/zsh/zshenv 2> /dev/null)
then
echo "$WARN_PREFIX Didn't find dotcfg(stow) alias, exporting to /etc/zsh/zshenv..."
echo alias dotcfg="stow -t ~" >> /etc/zsh/zshenv
fi

curl -Ss https://starship.rs/install.sh | sh

echo "Change to a normal user and install OhMyZSH..."
