#!/bin/bash

# Set to true to output debugging messages.
debug=true
usb_copy=true

# Function to output debug messages
debug_echo() {
    if [ "$debug" = true ]; then
        echo "$@"
    fi
}

debug_echo "debugging is on"

if [ "$usb_copy" = true ]; then
    debug_echo "usb_copy is set to true. udev rule will be created for picframe and video kiosk"
fi

debug_echo "Defining some variables."
script_path="/usr/bin/kiosk"  # Update with your actual path to kiosk script.
config_file="/home/pi/kiosk-config.txt"
system_service_dir="/etc/systemd/system/"
model=$(cat /proc/device-tree/model | tr -d '\0')

debug_echo "script_path defined as $script_path"
debug_echo "config_file defined as $config_file"
debug_echo "system_service_dir defined as $system_service_dir"
debug_echo "model is $model"

# Declare arrays
declare -a desktop_services
declare -a service_urls

# Function to read the config file and populate arrays
populate_arrays() {
    debug_echo "Entered function 'populate_arrays'."
    # Initialize arrays
    desktop_services=()
    service_urls=()
    if [ ! -f "$config_file" ]; then
        debug_echo "$config_file does not exist. Creating it."
        touch "$config_file"
    else
	debug_echo "$config_file already exists, nothing to do here."
    fi
    # Read the config file line by line
    debug_echo "Reading $config_file to populate list of options for menu."
    while IFS='|' read -r first_part second_part || [[ -n "$first_part" ]]; do
        desktop_services+=("$first_part")
        service_urls+=("$second_part")
    done < "$config_file"
    # Define arrays
    non_desktop_services=("picframe")
    all_services=()
    # Add additional options conditionally
    if [ ${#desktop_services[@]} -gt 0 ]; then
        all_services+=("${desktop_services[@]}")
    fi
    other_services=("video-kiosk")
    all_services+=("${non_desktop_services[@]}" "${other_services[@]}")
    all_options=("${all_services[@]}")  # Initialize with all_services
    all_options+=("add-new" "desktop" "remove-all" "Quit")
    debug_echo "List of options populated with the following items:"
    #unnecessary if functioning correctly.
    for option in "${all_options[@]}"; do
        debug_echo "$option"
    done
    debug_echo "Exiting function: 'populate_arrays'."
}

# Function to create udev rule that triggers usb copy script for picframe
create_custom_udev_rule() {
    if [ "$usb_copy" = true ]; then
        debug_echo "Entered function 'create_custom_udev_rule'."
        # Define the content of the udev rule
        rule_content='ACTION=="add", KERNEL=="sd*", SUBSYSTEMS=="usb", RUN+="/bin/systemctl start usb_copy.service"'
        # Define the file path
        file_path="/etc/udev/rules.d/99-custom-mount.rules"
        # Check if the file already exists, if not, create it
        if [ ! -e "$file_path" ]; then
            debug_echo "udev rule to control auto usb copying does not exist, creating the necessary file."
            echo "$rule_content" | sudo tee "$file_path" > /dev/null
            debug_echo "File $file_path created with custom rule."
            debug_echo "Reloading udev rules."
            sudo udevadm control --reload-rules
        else
            debug_echo "File $file_path already exists. Skipping creation."
        fi
        debug_echo "Exiting function: 'create_custom_udev_rule'."
    fi
}

# Function to remove udev rule that triggers usb copy script for picframe.
delete_custom_udev_rule() {
    if [ "$usb_copy" = true ]; then
        debug_echo "Entered function 'delete_custom_udev_rule'."
        # Define the file path
        file_path="/etc/udev/rules.d/99-custom-mount.rules"
        # Check if the file exists, if yes, delete it
        if [ -e "$file_path" ]; then
            debug_echo "Deleting udev rule that controls auto usb copy of images and video files."
            sudo rm "$file_path"
            debug_echo "File $file_path deleted."
            debug_echo "Reloading udev rules."
            sudo udevadm control --reload-rules
        else
            debug_echo "File $file_path does not exist. Nothing to delete."
        fi
        debug_echo "Exiting function: 'delete_custom_udev_rule'."
    fi
}

# Function to disable all services in the first and second arrays.
disable_services() {
    debug_echo "Entered function 'disable_services'."
    debug_echo "Disabling current services..."
    for service in "${all_services[@]}"; do
        if [[ "$service" == "picframe" ]]; then
            if [[ "$model" == *"Pi 3"* ]]; then
                if systemctl --user is-active --quiet "$service.service"; then
                    debug_echo "$service is active. Stopping and disabling now"
                    debug_echo "Stopping $service..."
                    systemctl --user stop "$service.service"
                    debug_echo "Disabling $service..."
                    systemctl --user disable "$service.service"
                fi
            elif [[ "$model" == *"Pi 4"* ]]; then
                if sudo systemctl is-active --quiet "$service.service"; then
                    debug_echo "$service is active. Stopping and disabling now"
                    debug_echo "Stopping $service..."
                    sudo systemctl stop "$service.service"
                    debug_echo "Disabling $service..."
                    sudo systemctl disable "$service.service"
                    debug_echo "Enabling desktop environment. Reboot is necessary."
                    enable_desktop
                fi
            else
                echo "Unknown model"
            fi
        else
            if sudo systemctl is-active --quiet "$service.service"; then
                if [[ "$service" == "video-kiosk" ]]; then
                    debug_echo "$service is active. Stopping and disabling now"
                    echo "Stopping video kiosk. This will take a few minutes"
                    echo "PLEASE BE PATIENT"
                fi
                debug_echo "Stopping $service..."
                sudo systemctl stop "$service.service"
                debug_echo "Disabling $service..."
                sudo systemctl disable "$service.service"
            fi
        fi
    done
    debug_echo "Exiting function: 'disable_services'."
}

# Function to delete all services in the first array.
delete_services() {
    debug_echo "Entered function 'delete_services'."
    for service in "${desktop_services[@]}"; do
        if sudo systemctl is-active --quiet "$service.service"; then
            sudo systemctl disable "$service.service"
            sudo systemctl stop "$service.service"
        fi
        debug_echo "Deleting $service..."
        # Check if the file exists, if so, delete it
        if [ ! -e "$system_service_dir""$service.service" ]; then
            debug_echo "$system_service_dir""$service.service does not exist, nothing to do here."
        else
            debug_echo "File $system_service_dir""$service.service exists. Deleting."
            sudo rm "$system_service_dir""$service.service"
            debug_echo "Reloading systemctl daemon"
            sudo systemctl daemon-reload
        fi
    done
    debug_echo "Exiting function: 'delete_services'."
}

# Function to enable desktop
enable_desktop() {
    debug_echo "Entered function 'enable_desktop'."
    # Set boot behavior to desktop
    sudo raspi-config nonint do_boot_behaviour B4
    debug_echo "Exiting function: 'enable_desktop'."
}

# Function to disable desktop
disable_desktop() {
    debug_echo "Entered function 'disable_desktop'."
    # Set boot behavior to console
    sudo raspi-config nonint do_boot_behaviour B2
    debug_echo "Exiting function: 'disable_desktop'."
}

# Function to enable PIC frame (not used in pi3)
enable_picframe() {
    debug_echo "Entered function 'enable_picframe'."
    if [[ "$model" == *"Pi 3"* ]]; then
        debug_echo "This is a Pi 3"
        # Enable PIC frame service
        systemctl --user enable "$selected_service.service"
        systemctl --user start "$selected_service.service"
    elif [[ "$model" == *"Pi 4"* ]]; then
        debug_echo "This is a Pi 4"
        debug_echo "Entered function 'enable_picframe'."
        # Disable desktop
        disable_desktop
        # Enable picframe service
        debug_echo "Enabling $selected_service"
        sudo systemctl enable "$selected_service.service"
        debug_echo "Exiting function: 'enable_picframe' with a reboot."
        debug_echo "Rebooting"
        # Reboot
        sudo reboot
    else
        echo "Unknown model"
    fi
}

# Function to enable selected service
enable_service() {
    debug_echo "Entered function 'enable_service'."
    disable_services
    if [ "$selected_service" == "picframe" ]; then
        enable_picframe
    else
        # Check if the service file exists
        debug_echo "Checking $selected_service file exists."
        if [ ! -f "$system_service_dir$selected_service.service" ]; then
            # If the service file doesn't exist, create it by copying from kiosk.service
            debug_echo "The file does not exist"
            sudo cp "$system_service_dir"kiosk.service "$system_service_dir$selected_service.service"
            debug_echo "Reloading systemctl daemon."
            sudo systemctl daemon-reload
        fi
        # Enable selected service
        if [[ "$model" == *"Pi 3"* ]]; then
            debug_echo "This is a Pi 3"
            sudo systemctl enable "$selected_service.service"
            sudo systemctl start "$selected_service.service"
        elif [[ "$model" == *"Pi 4"* ]]; then
            debug_echo "This is a Pi 4"
            debug_echo "Checking if X is running."
            if [ -z "$(pidof Xorg)" ]; then
                debug_echo "Desktop is not enabled. Enabling desktop and rebooting."
                sudo systemctl enable "$selected_service.service"
                enable_desktop
                sudo reboot
            else
                debug_echo "Desktop is enabled. Starting and enabling service."
                sudo systemctl enable "$selected_service.service"
                sudo systemctl start "$selected_service.service"
            fi
        else
            echo "Unknown model"
        fi
    fi
    debug_echo "Exiting function: 'enable_service'."
}

# Function to replace URL in kiosk.sh script
replace_url_in_kiosk_script() {
    debug_echo "Entered function 'replace_url_in_kiosk_script'."
    local new_url="$1"
    # Replace URL in the kiosk.sh script
    sudo sed -i "s|--kiosk .*|--kiosk $new_url \&|" "$script_path"
    debug_echo "URL replaced in $script_path"
    debug_echo "Exiting function: 'replace_url_in_kiosk_script'."
}

# Function to add new kiosk urls and a service name to go with it.
add_new_service() {
    debug_echo "Entered function 'add_new_service'."
    read -p "Enter the name of the new service: " new_service
    read -p "Enter the URL for the new service: " new_url
    echo "$new_service|$new_url" >> "$config_file"
    debug_echo "New service '$new_service' added with URL '$new_url'."
    debug_echo "Exiting function: 'add_new_service'."
}

# Functions for handling selections
handle_desktop() {
    debug_echo "Entered function 'handle_desktop'."
    debug_echo "Performing command for desktop..."
    delete_custom_udev_rule
    disable_services
    if [[ "$model" == *"Pi 4"* ]]; then
        enable_desktop
        # Checking if X is running
        if [ -z "$(pidof Xorg)" ]; then
            debug_echo "Desktop is not enabled. Rebooting."
            sudo reboot
        else
            debug_echo "Desktop is enabled. No need to reboot."
        fi
    fi
    debug_echo "Exiting function: 'handle_desktop'."
}

handle_remove_all() {
    debug_echo "Entered function 'handle_remove_all'."
    while true; do
        read -p "Are you sure you want to remove all services? This action cannot be undone. (yes/no): " confirmation
        case $confirmation in
            [Yy][Ee][Ss])
                debug_echo "Performing command for remove-all..."
                delete_services
                echo -n > /home/pi/kiosk-config.txt
                populate_arrays  # Reload arrays
                select_option    # Recall select_option
                break
                ;;
            [Nn][Oo])
                echo "Remove all services operation aborted."
                select_option
                break
                ;;
            *)
                echo "Invalid entry. Please enter 'yes' or 'no'."
                ;;
        esac
    done
    debug_echo "Exiting function: 'handle_remove_all'."
}

handle_add_new() {
    debug_echo "Entered function 'handle_add_new'."
    debug_echo "Performing command for add-new..."
    add_new_service
    populate_arrays  # Reload arrays
    select_option    # Recall select_option
    debug_echo "Exiting function: 'handle_add_new'."
}

handle_picframe(){
    debug_echo "Entered function 'handle_picframe'."
    debug_echo "Performing command for picframe..."
    create_custom_udev_rule
    enable_service
    debug_echo "Exiting function: 'handle_picframe'."
}

handle_video(){
    debug_echo "Entered function 'handle_video'."
    debug_echo "Performing command for video..."
    create_custom_udev_rule
    enable_service
    debug_echo "Exiting function: 'handle_video'."
}

handle_desktop_services() {
    debug_echo "Entered function 'handle_desktop_services'."
    debug_echo "Performing command for desktop service: $selected_service..."
    debug_echo "Corresponding URL: ${service_urls[$index]}"
    replace_url_in_kiosk_script "${service_urls[$index]}"
    delete_custom_udev_rule
    enable_service
    debug_echo "Exiting function: 'handle_desktop_services'."
}

# Function to select an option and perform commands
select_option() {
    debug_echo "Entered function 'select_option'."
    echo "Select an option:"
    for ((i=0; i<${#all_options[@]}; i++)); do
        echo "$((i+1)). ${all_options[$i]}"
    done

    read -p "Enter the number of the option: " choice
    index=$((choice-1))

    if ((index >= 0 && index < ${#all_options[@]})); then
        selected_service="${all_options[$index]}"
        case $selected_service in
            "Quit")
                echo "Quitting the script."
                exit 0
                ;;
            "desktop")
                handle_desktop
                ;;
            "remove-all")
                handle_remove_all
                ;;
            "add-new")
                handle_add_new
                ;;
            "picframe")
                handle_picframe
                ;;
            "video-kiosk")
                handle_video
                ;;
            *)
                if printf '%s\n' "${desktop_services[@]}" | grep -q "^$selected_service$"; then
                    # If selected_service is found in desktop_services array
                    handle_desktop_services
                else
                    echo "Invalid option."
                    select_option    # Recall select_option
                fi
                ;;
        esac
    else
        echo "Invalid option."
        select_option    # Recall select_option
    fi
    debug_echo "Exiting function: 'select_option'."
}


# Call the function to populate arrays
populate_arrays

# Call the function to select an option
select_option

