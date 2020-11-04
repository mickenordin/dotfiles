#!/usr/bin/env bash
BLACKLIST="gnome-keyring-daemon"
grep -s "Exec=" /etc/xdg/autostart/* ${HOME}/.config/autostart/* | awk -F '=' '{print "exec",$2}'| sort -u | egrep -v ${BLACKLIST} > ~/.config/sway/config.d/autostart
