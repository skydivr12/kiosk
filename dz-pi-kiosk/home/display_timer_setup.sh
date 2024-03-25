#!/bin/bash

timers=()
# Function to prompt for service details
prompt_for_service_details() {
    local path_to=/usr/bin
    local service_name=$1
    local start_times=()
    local days=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")

    # Prompt user for the time to start the service for each day of the week
    for day in "${days[@]}"; do
        read -p "Enter the time of day for $day (format HH:MM) to turn $service_name: " start_time
        start_times+=("$start_time")
    done

    # Create the systemd service unit file
    service_file="/etc/systemd/system/${service_name}.service"
    echo "[Unit]
Description=$service_name
After=multi-user.target

[Service]
Type=simple
ExecStart=sh $path_to/$service_name
" > "$service_file"

    echo "
[Install]
WantedBy=default.target" >> "$service_file"

    # Create the systemd timer unit file
    timer_file="/etc/systemd/system/${service_name}.timer"
    echo "[Unit]
Description=Timer for $service_name

[Timer]" > "$timer_file"

    for i in "${!days[@]}"; do
        echo "OnCalendar=${days[$i]} ${start_times[$i]}" >> "$timer_file"
    done

    echo "
[Install]
WantedBy=timers.target" >> "$timer_file"
timers+=($service_name)
}

# Prompt user for service details for display_on.service
prompt_for_service_details "display_on"

# Prompt user for service details for display_off.service
prompt_for_service_details "display_off"

# Reload systemd daemon to read the new unit files
sudo systemctl daemon-reload

echo "Timer and service files have been created successfully."
echo "Display will turn on and off at the times specified."

for timer in "${timers[@]}"; do
    sudo systemctl enable "$timer.timer"
    sudo systemctl start "$timer.timer"
done


