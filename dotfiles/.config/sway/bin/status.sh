#!/usr/bin/env bash
# The Sway configuration file in ~/.config/sway/config calls this script.
# You should see changes to the status bar after saving this script.
# If not, do "killall swaybar" and $mod+Shift+c to reload the configuration.

hostname=$(hostname --fqdn)
ip=$(hostname -I)

# Produces "21 days", for example
uptime_formatted=$(uptime | cut -d ',' -f1  | cut -d ' ' -f4,5)

# Date and time
date_formatted=$(date +'%Y-%m-%d %H:%M:%S')

# Get the Linux version but remove the "-1-amd64" part
linux_version=$(uname -r | cut -d '-' -f1)

# Returns the battery status: "Full", "Discharging", or "Charging".
battery_status=$(cat /sys/class/power_supply/BAT0/status)
battery_percent=$(cat /sys/class/power_supply/BAT0/capacity)

# Emojis and characters for the status bar
echo ${hostname} ${uptime_formatted} ↑ ${linux_version}  ${battery_percent}% ${battery_status} ⚡ ${date_formatted}  ${ip} 

