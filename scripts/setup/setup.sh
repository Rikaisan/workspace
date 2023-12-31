#!/usr/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_SSH_LINK=git@github.com:Rikaisan/arch-workspace.git

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
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "$PREFIX Setting up locales and time..."
    ln -sf /usr/share/zoneinfo/America/Bogota /etc/localtime
    hwclock --systohc
    printf "en_US.UTF-8 UTF-8\nen_GB.UTF-8 UTF-8\n" > /etc/locale.gen
    locale-gen
    printf "LANG=en_US.UTF-8\nLC_TIME=en_GB.UTF-8\n" > /etc/locale.conf

    read -p "$INPUT_PREFIX Type your desired hostname: " -r
    echo $RESULT > /etc/hostname
    printf "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n" >> /etc/hosts
    echo "$IMPORTANT_PREFIX Setup the password for root"
    passwd
fi

# ------------------------------------------------------------------------ User

read -p "$INPUT_PREFIX Type the username you want to use: " -r
USERNAME=$REPLY

if !(grep -q $USERNAME /etc/group 2> /dev/null)
then
    echo "$PREFIX creating user '$USERNAME'..."
    useradd -m -G wheel $USERNAME
    passwd $USERNAME
    echo "$SUCCESS_PREFIX User created!"
else
    echo "$PREFIX User already exists, skipping..."
fi




# ------------------------------------------------------------------------ Mirrors

# echo "$PREFIX Refreshing mirrors..."
# pacman -S --needed reflector
# reflector --save /etc/pacman.d/mirrorlist --ipv4 --ipv6 --protocol https --latest 20 --sort rate
printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf

# ------------------------------------------------------------------------ Paru

echo "$WARN_PREFIX git, sudo and rust will be installed if you don't have them."
echo "$PREFIX Installing paru..."
cd $SCRIPT_DIR
pacman -Sy
pacman -S --needed git base-devel sudo rustup
su $USERNAME -Pc "rustup default stable"

# echo "$IMPORTANT_PREFIX Run ./paru.sh to continue..."
# chmod +x $SCRIPT_DIR/paru.sh
# su $USERNAME
if ! command -v paru &> /dev/null
then
    su $USERNAME -Pc "git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -Ccsi"
    su $USERNAME -Pc "paru -Syu"
fi

rm -rf /tmp/paru
echo "$SUCCESS_PREFIX Finished installing paru."

# ------------------------------------------------------------------------ Packages

TMP_LIST_DIR=/tmp/ispackages
cd $SCRIPT_DIR
mkdir $TMP_LIST_DIR
cp *.lst $TMP_LIST_DIR/
chown -R $USERNAME:$USERNAME $TMP_LIST_DIR


# ------------------------------- Essential

echo "$PREFIX Installing essentials..."
su $USERNAME -Pc "cd $TMP_LIST_DIR && paru -S --needed - < essential.lst"

systemctl enable NetworkManager
systemctl enable bluetooth
# systemctl enable sshd
systemctl enable tlp

echo "$WARN_PREFIX Installing Starship..."
curl -sS https://starship.rs/install.sh | sh

echo "$SUCCESS_PREFIX Finished installing essential packages."

# ------------------------------- Optional

read -p "$INPUT_PREFIX Do you want to install the Hyprland environment?[y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    su $USERNAME -Pc "cd $TMP_LIST_DIR && paru -S --needed - < environment.lst"
    systemctl enable sddm
    ln -s /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 /usr/local/bin/polkit-gnome
    echo "$SUCCESS_PREFIX Done!"
fi


read -p "$INPUT_PREFIX Do you want to install the extra apps?[y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    su $USERNAME -Pc "cd $TMP_LIST_DIR && paru -S --needed - < extra.lst"
    usermod -aG docker $USERNAME
    echo "$SUCCESS_PREFIX Done!"
fi

rm -rf $TMP_LIST_DIR

# ------------------------------- Bootloader

read -p "$IMPORTANT_PREFIX Do you want to install the bootloader(GRUB)?[y/N] " -n 1 -r
echo
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

# ------------------------------------------------------------------------ Env Variables

cd $SCRIPT_DIR

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
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "$PREFIX Copying dotfiles..."
    DOTFILES_DIR=/home/$USERNAME/source/workspace/dotfiles
    mkdir -p $DOTFILES_DIR
    cd $SCRIPT_DIR
    cp -r ../../* $DOTFILES_DIR/

    cd $DOTFILES_DIR

    # git remote rm origin
    # git remote add origin $REPO_SSH_LINK

    for dir in $DOTFILES_DIR/*  # list directories in the form "/tmp/dirname/"
    do
        dir=${dir%*/}      # remove the trailing "/"
        dir=${dir##*/}    # print everything after the final "/"

        stow -t /home/$USERNAME/ $dir
    done
    cd /home
    chown -R $USERNAME:$USERNAME $USERNAME
    echo "$SUCCESS_PREFIX Done!"
fi

# ------------------------------------------------------------------------ Finished, wahoo!

read -p "$PREFIX Finished the workspace setup, reboot?[y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
   reboot
fi
