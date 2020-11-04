#!/usr/bin/env bash
grep -s "Exec=" /etc/xdg/autostart/* ${HOME}/.config/autostart/* | awk -F '=' '{print "exec",$2}'| sort -u > ~/.config/sway/config.d/autostart
