#!/usr/bin/env bash

warning=10
error=5

while true; do
    battery_status=$(cat /sys/class/power_supply/BAT0/status)
    battery_percent=$(cat /sys/class/power_supply/BAT0/capacity)
    if [[ "${battery_status}" == "Discharging" ]] &&  [[ ${battery_percent} -lt ${warning} ]]; then
        mtype="warning"
        if [[ ${battery_percent} -lt ${error} ]]; then
            mtype="error"
        fi
        /usr/bin/swaynag -o eDP-1 -s "Dismiss" -e bottom -t ${mtype} -m "${mtype^^}: Battery at ${battery_percent}%"
    fi
    sleep 60
done
exit 0
