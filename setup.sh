#!/usr/bin/env bash
# You must have sudo before running this script
# su -
# apt install sudo
# usermod -a -G sudo <your username>

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
	emacs \
	firefox-esr \
	fish \
	geary \
	git \
	jq \
	keepassxc \
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
	ninja-build \
	nm-tray \
	pavucontrol \
	ranger \
	ripgrep \
	rsync \
	scdoc \
	sway \
	vim \
	wayland-protocols \
	webext-keepassxc-browser \
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

sudo echo '#!/bin/sh
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
patch -p1 < ../effects.c.patch
meson build
ninja -C build
sudo ninja -C build install

# Doom emacs
cd ~/sources
git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d
~/.emacs.d/bin/doom install

#ncspot
cd ~/sources
git clone https://github.com/hrkfdn/ncspot.git
cd ncspot
cargo build --release
sudo cp target/release/ncspot /usr/local/bin/

# dotfiles
cd ${WORKDIR}
rsync -a dotfiles/ ~/

# Fish and oh my fish
curl -L https://get.oh-my.fish | fish
omf install agnoster
chsh -s (which fish)

echo "Follow this instruction if gnome-keyring gives you trouble: https://wiki.archlinux.org/index.php/GNOME/Keyring#Using_the_keyring_outside_GNOME"
echo "Rebooting in 5 seconds"
sleep 5s
sudo reboot
