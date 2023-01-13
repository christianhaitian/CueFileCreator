#!/bin/bash

#IFS=';'

sudo chmod 666 /dev/tty1
export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/
printf "\033c" > /dev/tty1
dialog --clear
height="15"
width="55"

if [ -f "/opt/system/Advanced/Switch to main SD for Roms.sh" ]; then
  whichsd="roms2"
elif [ -f "/storage/.config/.OS_ARCH" ] || [ "${OS_NAME}" == "JELOS" ]; then
  whichsd="storage/roms"
else
  whichsd="roms"
fi

if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  param_device="anbernic"
  if [ -f "/boot/rk3326-rg351v-linux.dtb" ] || [ $(cat "/storage/.config/.OS_ARCH") == "RG351V" ]; then
    sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
    height="20"
    width="60"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if [[ ! -z $(cat /etc/emulationstation/es_input.cfg | grep "190000004b4800000010000001010000") ]]; then
    param_device="oga"
	hotkey="Minus"
  else
	param_device="rk2020"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo3-joypad-event-joystick" ]]; then
  param_device="ogs"
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
  if [ "$(cat ~/.config/.OS)" == "ArkOS" ] && [ "$(cat ~/.config/.DEVICE)" == "RGB10MAX" ]; then
	height="30"
	width="110"
	hotkey="Minus"
  fi
elif [[ -e "/dev/input/by-path/platform-singleadc-joypad-event-joystick" ]]; then
  #if [ "${OS_NAME}" == "JELOS" ]; then
    #param_device="rg552"
  #else
    param_device="rg503"
  #fi
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
else
  param_device="chi"
  hotkey="1"
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
fi

# Start oga_controls
cd /${whichsd}/tools/CueFileCreator
sudo kill -9 $(pidof oga_controls)
sudo ./oga_controls Cue_Creator_Too $param_device > /dev/null 2>&1 &

# Verify dialog is installed and if not, install it
dpkg -s "dialog" &>/dev/null
if [ "$?" != "0" ]; then
  sudo apt update && sudo apt install -y dialog --no-install-recommends
  temp=$(grep "title=" /usr/share/plymouth/themes/text.plymouth)
fi

# Welcome
 dialog --backtitle "CUE File Creator" --title "CUE File Creator Utility" \
    --yesno "\nThe script will automate the creation of CUE files for all the .bin files found in various CD based roms path.\n
	The main python script used by this tool was originally created by A Former User for Retropie. \n(https://retropie.org.uk/forum/topic/31984/psx-cue-file-maker-script)
 \n\n\nDo you want to proceed?" $height $width 2>&1 > /dev/tty1

case $? in
       1) sudo kill -9 $(pidof oga_controls)
          sudo systemctl restart oga_events &
          exit
          ;;
esac

userExit() {
  sudo kill -9 $(pidof oga_controls)
  sudo systemctl restart oga_events &
  dialog --clear
  printf "\033c" > /dev/tty1
  exit 0
}

function main_menu() {
    local options=( "$whichsd/dreamcast" 1 "$whichsd/psx" 2 "$whichsd/segacd" 3 "$whichsd/pcfx" 4 )

    while true; do
		selection=(dialog \
		--backtitle "CUE File Creator" \
		--title " MAIN MENU " \
		--no-collapse \
		--clear \
        --cancel-label "Exit" \
        --menu "What CD based game system folders would you like scanned and CUE files created for" $height $width 15 )

        choices=$("${selection[@]}" "${options[@]}" 2>&1 > /dev/tty1) || userExit

        for choice in $choices; do
          case $choice in
			*) python3 CueFileCreator.py "/$choice/"  ;;
          esac
        done
	done
}

# Main

main_menu
sudo kill -9 $(pidof oga_controls)
sudo systemctl restart oga_events &
