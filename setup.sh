#!/usr/bin/env bash
# You must have sudo before running this script
su - -c "apt install sudo"
su - -c "usermod -a -G sudo ${USER}"

# Set up various variables 
WORKDIR="$(pwd)"
GREETDSWAYCONFIG="/etc/greetd/sway-config"
GREETDCONFIG="/etc/greetd/config.toml"
GREETDENVS="/etc/greetd/environments"
SWAYRUN="/usr/local/bin/sway-run.sh"
WAYLAND_ENABLE="/usr/local/bin/wayland_enablement.sh"

# Install software from repo
sudo apt install \
	build-essential \
	cargo \
	curl \
	davfs2 \
	exa \
	firefox-esr \
	fish \
	git \
	j4-dmenu-desktop \
	jq \
	libcairo-dev  \
	libdbus-1-dev \
	libncursesw5-dev \
	libpam-dev \
	libpam0g-dev \
	libpulse-dev \
	libssl-dev \
	libwayland-dev \
	libxcb-render0-dev \
	libxcb-shape0-dev \
	libxcb-xfixes0-dev \
	libxcb1-dev \
	libxkbcommon-dev \
	light \
	meson \
	mpv \
	neovim \
	neomutt \
	ninja-build \
	nm-tray \
	pass \
	pavucontrol \
	pandoc \
	poppler-utils \
	python3-pip \
	qutebrowser \
	ripgrep \
	rsync \
	scdoc \
	sway \
	unzip \
	wayland-protocols \
	wl-clipboard  \
	wlr-randr
# Fix NextCloud stuff
sudo usermod -a -G davfs2 ${USER}
mkdir -p ~/nextcloud
mkdir -p ~/.davfs2
sudo cp  /etc/davfs2/secrets ~/.davfs2/secrets
sudo chown ${USER}:${USER} ~/.davfs2/secrets
chmod 600 ~/.davfs2/secrets
echo -n "Enter Nextcloud server, e.g. https://example.com: "
read server
echo -n "Enter Nextcloud user: "
read user
echo -n "Enter Nextcloud password: "
read -s password
echo ""
fullserver="${server}/remote.php/dav/files/${user}/"
echo "${fullserver} ${user} ${password}" >> ~/.davfs2/secrets

fstab=$(grep ${server} /etc/fstab)
if [[ "x${fstab}" == "x" ]]; then
	echo "${fullserver} /home/${USER}/nextcloud davfs user,rw,auto 0 0" | sudo tee -a /etc/fstab
else
	echo /etc/fstab allready configured
fi

# Fix nm-tray icon
nm=$(grep QT_QPA_PLATFORMTHEME /etc/security/pam_env.conf)
if [[ "x${nm}" == "x" ]]; then
	echo 'QT_QPA_PLATFORMTHEME DEFAULT=qt5ct' | sudo tee -a /etc/security/pam_env.conf
fi

# Install software from sources
mkdir -p ~/sources
cd ~/sources
# Greetd
git clone  https://git.sr.ht/~kennylevinsen/greetd
cd greetd
# Compile greetd and agreety.
cargo build --release

# Put things into place
sudo cp target/release/{greetd,agreety} /usr/local/bin/
sudo cp greetd.service /etc/systemd/system/greetd.service
sudo mkdir -p /etc/greetd

# Create the greeter user
sudo useradd -M -G video greeter
sudo chown -R greeter:greeter /etc/greetd/

#wlgreet
cd ~/sources
git clone https://git.sr.ht/~kennylevinsen/wlgreet
cd wlgreet
cargo build --release
sudo cp target/release/wlgreet /usr/local/bin/
echo 'exec "wlgreet --command sway; swaymsg exit"

bindsym Mod4+shift+e exec swaynag \
	-t warning \
	-m "What do you want to do?" \
	-b "Poweroff" "systemctl poweroff" \
	-b "Reboot" "systemctl reboot"

include /etc/sway/config.d/*
' | sudo tee ${GREETDSWAYCONFIG}

echo '[terminal]
vt = 1

[default_session]
command = "sway --config /etc/greetd/sway-config"
user = "greeter"
' | sudo tee ${GREETDCONFIG}

echo 'sway
bash
' | sudo tee ${GREETDENVS}

echo '#!/bin/sh

# Session
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export XDG_CURRENT_DESKTOP=sway

source /usr/local/bin/wayland_enablement.sh

systemd-cat --identifier=sway sway $@
' | sudo tee ${SWAYRUN}

echo '#!/bin/sh
export MOZ_ENABLE_WAYLAND=1
export CLUTTER_BACKEND=wayland
export QT_QPA_PLATFORM=wayland-egl
export ECORE_EVAS_ENGINE=wayland-egl
export ELM_ENGINE=wayland_egl
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export NO_AT_BRIDGE=1' | sudo tee ${WAYLAND_ENABLE}

sudo chmod +x ${SWAYRUN} ${WAYLAND_ENABLE}

# enable greetd
sudo systemctl enable greetd

# Swaylock-effects
cd ~/sources
git clone https://github.com/mortie/swaylock-effects.git
cd swaylock-effects
meson build
ninja -C build
sudo ninja -C build install

# Autotiling
sudo -H pip install autotiling

#ncspot
cd ~/sources
git clone https://github.com/hrkfdn/ncspot.git
cd ncspot
cargo build --release
sudo cp target/release/ncspot /usr/local/bin/

# Card/Cal
sudo pip3 install vdirsyncer khal khard
vdirsyncer discover contacts
vdirsyncer discover calendar
vdirsyncer sync

# Firefox pass host app
curl -sSL github.com/passff/passff-host/releases/latest/download/install_host_app.sh | bash -s -- firefox

# dotfiles
cd ${WORKDIR}
rsync -a dotfiles/ ~/

# Background
sudo mkdir -p /usr/local/share/backgrounds
sudo wget https://www.publicdomainpictures.net/pictures/230000/velka/night-landscape-15010066769pV.jpg -O /usr/local/share/backgrounds/night-landscape.jpg

# VictoMono font
cd /tmp
mkdir fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/VictorMono.zip
unzip VictorMono.zip
sudo cp *tf /usr/local/share/fonts
cd ..
rm -rf fonts

# Fish and oh my fish
curl -L https://get.oh-my.fish | fish
omf install agnoster
chsh -s (which fish)

echo "Make sure you have you gpg-key imported and trusted"

echo "Follow this instruction if gnome-keyring gives you trouble: https://wiki.archlinux.org/index.php/GNOME/Keyring#Using_the_keyring_outside_GNOME"
echo "Rebooting in 5 seconds"
sleep 5s
sudo reboot
