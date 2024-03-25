# Initial setup instructions:
## Equipment needed:
1. Raspberry Pi 3
2. A high quality SD card (32GB minimum)
3. An official power supply.
4. An internet connection. Wireless or ethernet. (optional)
5. A computer with an SD card reader with Raspberry Pi Imager installed.
6. A usb mouse and keyboard. (only necessary if there is no internet connection.)
7. SD card with dz-pi3.img file on it.

## Setup steps.
8.  Copy dz-pi3.img file from sd card to computer. (remember where you save it.)
9.  Insert blank SD card into computer.
10. Burn image to sd card.
  a.  Open Raspberry Pi Imager
  b.  Click the "CHOOSE DEVICE" button and select raspberry pi 3.
  c.  Click "CHOOSE OS" button and scroll all the way to the bottom and select
      use custom.
  d.  Navigate to and select dz-pi.img from where you saved it on your computer.
  e.  Click the "CHOOSE STORAGE" button and select the SD card.
  f.  Hit the "NEXT" button then select "NO". Image will start burning to the SD
      card.
11. Connect Raspberry Pi.
  a.  HDMI
  b.  Ethernet (if using wired connection)
  c.  Mouse and keyboard (if using wireless connection)
  d.  DO NOT CONNECT POWER YET.
12. Once the image is finished burning, insert SD card into Rasberry Pi.
13. Insert power cable.

## Finishing steps (These cannot be skipped)
## If not connecting to a network skip to step 16
14. Establish network connection. (skip to step 15 if using ethernet.)
  a.  Use the mouse and click the network icon in the upper right corner of the
      screen.
  b.  Select your network and use keyboard to enter network password.
  c.  Once connected, hover your mouse cursor over network icon, make note of IP
      address.
15. On your computer, open the command prompt and enter this command: "ssh pi@dz-pi3"
  a.  It should prompt you for a password. The current password is "skydive"
  b.  If this does not establish a connection, see step 14c. try again using the ip
      address instead of "dz-pi3"
  c.  You should now have a prompt that looks like this: "pi@dz-pi" in green
      lettering.
16. If not connecting to a network use the mouse and keybord to open a terminal.
    (black square icon upper left corner)
17. Enter the following command: "sudo raspi-config". A configuration utility will
    open.
  a.  Use arrow keys to scroll down to "Advanced Options". Hit Enter.
  b.  Ensure "Expand Filesystem" is highlighted and hit Enter.
  c.  Ensure "System Options" is highlighted and hit Enter.
  d.  Use arrow keys to scroll down to "Hostname" hit Enter.
  e.  With "ok" highlighted hit Enter again.
  f.  Enter a new hostname and hit Enter.
  g.  Repeat from step c. to change password as well.
  h.  Make sure you write down or make a note of the Hostname and Password as you
      will use these to log back into the Raspberry Pi.
  i.  Hit the TAB key twice to highlight "Finish" and hit Enter.
  j.  Select "Yes" to reboot now.
18. Reconnect with ssh command used earlier but with new hostname or
    reopen terminal once back on.

## Optional setup steps.
### Skip 19 if not using a power button.
19. Enter the following commands:
  a.  "sudo systemctl enable listen-for-shutdown.service"
  b.  "sudo systemctl start listen-for-shutdown.service"

### If you would like to schedule times for the raspberry pi to turn off the
### display automatically do step 20. If the raspberry pi will not be connected
### to a network then skip this step. This does NOT turn the raspberry pi off,
### it only disables output to the HDMI. Which can be used to turn off the tv,
### but not turn them back on. Most tvs do not have a wake on signal function.
20. Enter the command "sudo bash /home/pi/display_timer_setup.sh"
  a. You will be prompted to enter the time you would like the display to turn
     on and off for each day of the week.

# Final configuration.
21. Read the rest of this document for instructions and information on how to
    operate the kiosk functions of this raspberry pi build.
  a. Enter the command "mode" to complete setup.

# About this OS
This Raspberry Pi build has been optimized for a kiosk setup. It is built
on the Raspbian OS Buster operating system. Designed to be easily setup
with minimal interaction. Setting up a kiosk service that displays a
pictureframe, video kiosk, or webpage kiosk is easily facilitated by a setup
script that can be found on the desktop (Kiosk Mode Setup), or by typing
'mode' in a terminal window. When run it will prompt the user to select from
a list of options. After which it will reboot in the selected mode.

# Picture frame mode:
There is a built in digital picture frame software that is highly
configurable. Information on how to configure the picture frame viewer can
be found at thedigitalpictureframe.com. It is currently configured with my
favorite settings but these can be easily changed. The Pi3D pictureframe
software is very powerful and there is a tremendous amount of documentation
on how to use it so i recommend taking some time to look through some of the
resources at the digitalpictureframe.com.

# Webpage kiosk mode:
There are currently no webpage kiosks set but adding one is as easy as
selecting "add-new" from the selection list, giving a name for the service,
and a web address to display. When entering a web address type the whole
thing including the https. example: https://google.com If you want the kiosk
to rotate between multiple webpages simply enter the addresses of each webpage
when prompted for a url separating each with a space. example:
https://google.com https://duckduckgo.com You can enter as many webpages as
you want and it will cycle between them in ten second intervals. This is
achieved using the chrome browser extension Revolver. To change the length of
time each page is displayed, manually open the web browser, click on the
extensions icon, find the drop down menu for Revolver and select options.
From here you can adjust the length of time each page is displayed before
switching to the next tab. Once a kiosk service is setup it will remain until
remove-all is selected from the menu. You can setup as many different kiosk
services as you want. This way you can switch between different setups
quickly and easily using the mode command.

# Remote connect and control
Since managing a Raspberry Pi is most easily done from another computer, both
ssh and VNC are enabled by default. There are plenty of online resources
about both of these connection methods.

# Automatic image and video copy
In either picture frame or video kiosk mode there is an automatic usb copy
feature that will search any usb drive inserted for picture or video files
and copy them into their respective folders. This feature is only enabled
in these two modes but can be performed manually with this command:
"usb_copy"

# Flashing LED while copying.
The script that controls the automatic copying from usb drive also controls
and LED if one is wired to the GPIO pins. during the copy process the LED
will flash. Once copying is complete and the drive is safe to remove the
LED will turn off. This functionality can be enabled or disabled by modifying
the "/usr/bin/usb_copy" file and changing the use_led value to True or False.

# Automatically turn display on and off at specified times.
To setup times for automatic turning on and off of the display. type this
command: "sudo bash display_timer_setup.sh". it will then prompt you to
enter the time of day for each day of the week that you want it to turn on,
and what time you want it to go off. (Note: This does not turn off the
Raspberry pi, it only disables output to the HDMI.) once complete, the
display will automatically turn off and on at the specified times. (Note:
TVs generally do not have a 'wake on signal' feature the way most computer
monitors do. so while your tv may turn itself off you will need to manually
turn it back on.) Advanced: if you want to edit these timers manually they
can be edited with "sudo nano /etc/systemd/system/display_on.timer" There
is a .timer and .service file for each of display_on and display_off.

# Power button
If you connect a simple button to pins 5 and 6 you can take advantage of the
power button feature. When connected a push of the button will issue the
proper shutdown command to gracefully power off the pi. Press the button
while off and it will power the pi back up.

# Create departure viewer
To create the necessary file to run the departure viewer, type the following
command "bash create_departure_viewer.sh". It will prompt you for the
following information: the domain name of the network, the username, the
password, and the IP address. If you are unsure of what these values are you
will need to contact the network administrator.
