#!/bin/bash

##unfinished work in progress.

bin_origin=~/dz-pi-kiosk/bin/
sys_origin=~/dz-pi-kiosk/sys/
home_origin=~/dz-pi-kiosk/home/
bin_dest=/usr/bin/
sys_dest=/etc/systemd/system/
pi3_sys_dest=~/.config/systemd/user/

origin_directories=("$bin_origin" "$sys_origin" "$home_origin")

debug=true

debug_echo () {
    if [ "$debug" = true ]; then
        echo "$@"
    fi
}

for directory in "${origin_directories[@]}"; do
    debug_echo "copying files from $directory"
    for file in $(find "$directory"/*); do
        debug_echo "$file copied"
    done
done
