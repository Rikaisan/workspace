#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

GREEN="$(tput setaf 2)"
RED="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
PINK="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
RESET="$(tput sgr0)"

PREFIX="$CYAN[Workspace Setup]$RESET"
SUCCESS_PREFIX="$GREEN[Workspace Success]$RESET"
IMPORTANT_PREFIX="$RED[Workspace Important]$RESET"
WARN_PREFIX="$YELLOW[Workspace Warn]$RESET"
INPUT_PREFIX="$PINK[Workspace Input]$RESET"

# ------------------------------------------------------------------------ First-boot setup

read -p "$INPUT_PREFIX Do you want to perform the first-boot setup?[y/N] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "$PREFIX Setting up locales and time..."
    ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime
    hwclock --systohc
    echo en_US.UTF8 UTF8 >> /etc/locale.gen
    echo en_GB.UTF8 UTF8 >> /etc/locale.gen
    locale-gen
    echo LANG=en_US.UTF8 >> /etc/locale.conf
    echo LC_TIME=en_GB.UTF8 >> /etc/locale.conf

    read -p "$INPUT_PREFIX Type your desired hostname: " -r
    echo $RESULT >> /etc/hostname
    echo "$IMPORTANT_PREFIX Setup the password for root"
    passwd
fi

# ------------------------------------------------------------------------ Mirrors

echo "$PREFIX Refreshing mirrors..."
reflector --save /etc/pacman.d/mirrorlist --ipv4 --ipv6 --protocol https --latest 20 --sort rate

# ------------------------------------------------------------------------ Paru

echo "$WARN_PREFIX git will be installed if you don't have it."
echo "$PREFIX Installing paru..."
cd $SCRIPT_DIR
pacman -S --needed git
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -Ccsi
cd ..
rm -rf paru
echo "$SUCCESS_PREFIX Finished installing paru."

# ------------------------------------------------------------------------ Packages

# ------------------------------- Essential

echo "$PREFIX Installing essentials..."
paru -S --needed base-devel rustup
echo "$WARN_PREFIX Installing Rust..."
rustup default stable

paru -S --needed - < essentials.pkglist
systemctl enable NetworkManager

echo "$WARN_PREFIX Installing Starship..."
curl -sS https://starship.rs/install.sh | sh

echo "$SUCCESS_PREFIX Finished installing essential packages."

# ------------------------------- Optional

read -p "$INPUT_PREFIX Do you want to install the Hyprland environment?[y/N] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    paru -S --needed - < environment.pkglist
    systemctl enable SDDM
    echo "$SUCCESS_PREFIX Done!"
fi


read -p "$INPUT_PREFIX Do you want to install the extra apps?[y/N] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    paru -S --needed - < extra.pkglist
    echo "$SUCCESS_PREFIX Done!"
fi

# ------------------------------- Bootloader

read -p "$IMPORTANT_PREFIX Do you want to install the bootloader(GRUB)?[y/N] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mkinitcpio -P
    echo "$IMPORTANT_PREFIX Downloading necessary packages..."
    pacman -S --needed grub efibootmgr
    echo "$IMPORTANT_PREFIX Installing..."
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "$SUCCESS_PREFIX Done!"
fi

# ------------------------------------------------------------------------ User

read -p "$INPUT_PREFIX Type the username you want to use: " -r
USERNAME=$REPLY

echo "$PREFIX creating user '$USERNAME'..."
useradd -m -G wheel $USERNAME
passwd $USERNAME
echo "$SUCCESS_PREFIX User created!"

# ------------------------------------------------------------------------ Env Variables

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

# ------------------------------------------------------------------------ ZSH

echo "$PREFIX Installing ZPlug (zsh plugin manager)..."
export ZPLUG_HOME=/home/$USERNAME/.config/zplug
git clone https://github.com/zplug/zplug $ZPLUG_HOME

# ------------------------------------------------------------------------ Dotfiles

read -p "$IMPORTANT_PREFIX Do you want to link the dotfiles?[y/N] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "$PREFIX Copying dotfiles..."
    cp -r ../../dotfiles /home/$USERNAME/

    cd /home/$USERNAME/dotfiles
    for dir in /home/$USERNAME/dotfiles     # list directories in the form "/tmp/dirname/"
    do
        dir=${dir%*/}      # remove the trailing "/"
        dir=${dir##*/}    # print everything after the final "/"

        stow -t /home/$USERNAME $dir
    done
    echo "$SUCCESS_PREFIX Done!"
fi

# ------------------------------------------------------------------------ Finished, wahoo!

read -p "$PREFIX Finished the workspace setup, reboot?[y/N] " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
   reboot
fi
