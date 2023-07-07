echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh

echo "Opening Gogh, be sure to install Catppuccin Mocha..."
bash -c  "$(wget -qO- https://git.io/vQgMr)" 

echo "Installing paru..."
git clone https://aur.archlinux.org/paru-git.git
cd paru-git
makepkg -si
cd ..
rm -rf paru-git
