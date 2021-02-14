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
GTK_THEME=Adwaita:dark

# Add my own repo
wget -O - 'https://repo.mic.ke/PUBLIC.KEY' | sudo apt-key add -
wget -O - 'https://repo.mic.ke/debian/debian-micke-unstable.list' | sudo tee /etc/apt/sources.list.d/debian-micke-unstable.list

# Add linux-libre repo
wget -O - 'https://jxself.org/gpg.asc' | sudo apt-key add -
echo 'deb  https://mirror.linux.pizza/linux-libre/freesh/ freesh main
' | sudo tee /etc/apt/sources.list.d/linux-libre.list

# Add repo for tlpui 
wget -O - 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1cc3d16e460a94ee17fe581cea8cacc073c3db2a' | sudo apt-key add -
echo 'deb http://ppa.launchpad.net/linuxuprising/apps/ubuntu focal main 
deb-src http://ppa.launchpad.net/linuxuprising/apps/ubuntu focal main
' | sudo tee /etc/apt/sources.list.d/linuxuprising-apps.list

# Add system76 repo
wget -O - 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x5d1f3a80254f6afba254fed5acd442d1c8b7748b' | sudo apt-key add -
echo 'deb http://ppa.launchpad.net/system76-dev/stable/ubuntu focal main 
deb-src http://ppa.launchpad.net/system76-dev/stable/ubuntu focal main
' | sudo tee /etc/apt/sources.list.d/system76-dev.list

# Update repos
sudo apt update

# Install software from repo
sudo apt install \
    acpi \
    acpi-support \
    adwaita-qt \
    build-essential \
    cargo \
    cheese \
    cmake \
    curl \
    elinks \
    file-roller \
    firefox-esr \
    firmware-manager \
    fish \
    geany \
    geany-plugins \
    git \
    gnome-themes-extra \
    grub-coreboot \
    jq \
    libcairo-dev  \
    libdbus-1-dev \
    libgtkmm-3.0-dev \
    libncursesw5-dev \
    libpam-dev \
    libpam0g-dev \
    libpipewire-0.3-dev \
    libpulse-dev \
    libssl-dev \
    libsystemd-dev \
    libwayland-dev \
    libxcb-render0-dev \
    libxcb-shape0-dev \
    libxcb-xfixes0-dev \
    libxcb1-dev \
    libxkbcommon-dev \
    light \
    linux-libre \
    lxappearance \
    meson \
    mpv \
    neomutt \
    neovim \
    nextcloud-desktop \
    ninja-build \
    pandoc \
    pass \
    pavucontrol \
    pcmanfm \
    pipewire \
    poppler-utils \
    python3-pip \
    python3-tldextract \
    qt5ct \
    qutebrowser \
    ripgrep \
    rsync \
    seahorse \
    scdoc \
    sway \
    swayidle \
    swayswitch \
    system76-firmware-daemon \
    system76-power \
    tlp \
    tlpui \
    ukui-polkit \
    unzip \
    wayland-protocols \
    wl-clipboard  \
    wlr-randr \
    zsh
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

# Grid menu
git clone https://github.com/nwg-piotr/nwg-launchers.git
cd nwg-launchers
meson builddir -Dbuildtype=release
ninja -C builddir
sudo ninja -C builddir install
#sudo ninja -C builddir uninstall

# Autotiling
sudo -H pip install autotiling

# j4-dmenu-desktop
cd ~/sources
git clone https://github.com/enkore/j4-dmenu-desktop.git
cd j4-dmenu-desktop
cmake .
make
sudo make install

#ncspot
cd ~/sources
git clone https://github.com/hrkfdn/ncspot.git
cd ncspot
cargo build --release
sudo cp target/release/ncspot /usr/local/bin/

# xdg-desktop-portal-wlr
cd ~/sources
git clone https://github.com/emersion/xdg-desktop-portal-wlr
cd xdg-desktop-portal-wlr
meson build
ninja -C build
sudo ninja -C build install

# Vdirsyncer
cd ~/sources
git clone https://github.com/pimutils/vdirsyncer
cd vdirsyncer
python3 -m pip install --user --upgrade setuptools wheel
python3 setup.py sdist bdist_wheel
sudo python3 setup.py install

# dotfiles
cd ${WORKDIR}
rsync -a dotfiles/ ~/

# Card/Cal
sudo pip3 install khal khard
vdirsyncer discover contacts
vdirsyncer discover calendar
vdirsyncer sync

# Firefox pass host app
curl -sSL github.com/passff/passff-host/releases/latest/download/install_host_app.sh | bash -s -- firefox

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

# Set up GTK_THEME
grep GTK_THEME /etc/environment
if [[$? != 0]];
    echo "GTK_THEME=${GTK_THEME}" | sudo tee -a /etc/environment
fi

#lsd
wget https://github.com/Peltoche/lsd/releases/download/0.19.0/lsd-musl_0.19.0_amd64.deb
sudo dpkg -i lsd-musl_0.19.0_amd64.deb

# Appimage
wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb
sudo dpkg -i appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb
sudo apt -f install

# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
omz theme use agnoster

# Fish and oh my fish
curl -L https://get.oh-my.fish | fish
omf install agnoster

echo "Make sure you have you gpg-key imported and trusted"

echo "Follow this instruction if gnome-keyring gives you trouble: https://wiki.archlinux.org/index.php/GNOME/Keyring#Using_the_keyring_outside_GNOME"
echo "Rebooting in 5 seconds"
sleep 5s
sudo reboot
