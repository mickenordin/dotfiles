#!/usr/bin/env bash
# I run this in crontab every five minutes

warning=10
error=5

battery_percent="$(cat /sys/class/power_supply/BAT0/capacity)"

if [[ ${battery_percent} -gt ${warning} ]]; then
    exit 0
fi
if [[ ${battery_percent} -lt ${warning} ]]; then
    mtype="warning"
fi
if [[ ${battery_percent} -lt ${error} ]]; then
    mtype="error"
fi
swaynag -s "Dismiss" -e bottom -t ${mtype} -m "WARNING: Battery at ${battery_percent}%"
exit 0
