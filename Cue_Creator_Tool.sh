#!/bin/bash

#IFS=';'

ESUDO="sudo"
if [ $? != 0 ]; then
  ESUDO=""
fi
$ESUDO chmod 666 /dev/tty1
export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/
printf "\033c" > /dev/tty1
dialog --clear
hotkey="Select"
height="15"
width="55"
rm /dev/shm/CueFileCreator.log

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
    $ESUDO setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
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
  $ESUDO setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
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
  $ESUDO setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
else
  param_device="chi"
  hotkey="1"
  $ESUDO setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
fi

# Start oga_controls
cd /${whichsd}/tools/CueFileCreator
$ESUDO kill -9 $(pidof oga_controls)
$ESUDO ./oga_controls Cue_Creator_Too $param_device > /dev/null 2>&1 &

# Verify dialog is installed and if not, install it
dpkg -s "dialog" &>/dev/null
if [ "$?" != "0" ]; then
  $ESUDO apt update && $ESUDO apt install -y dialog --no-install-recommends
  temp=$(grep "title=" /usr/share/plymouth/themes/text.plymouth)
fi

# Welcome
 dialog --backtitle "CUE File Creator" --title "CUE File Creator Utility" \
    --yesno "\nThe script will automate the creation of CUE files for all the .bin files found in various CD based roms path.\n
	The main python script used by this tool was originally created by A Former User for Retropie. \n(https://retropie.org.uk/forum/topic/31984/psx-cue-file-maker-script)
 \n\n\nDo you want to proceed?" $height $width 2>&1 > /dev/tty1

case $? in
       1) $ESUDO kill -9 $(pidof oga_controls)
          $ESUDO systemctl restart oga_events &
          exit
          ;;
esac

userExit() {
  $ESUDO kill -9 $(pidof oga_controls)
  $ESUDO systemctl restart oga_events &
  dialog --clear
  printf "\033c" > /dev/tty1
  exit 0
}

function main_menu() {
    local options=( "$whichsd/dreamcast" "" \
                    "$whichsd/pcfx" "" \
                    "$whichsd/psx" "" \
                    "$whichsd/segacd" "" )

    while true; do
       selection=(dialog \
        --backtitle "CUE File Creator" \
        --title " MAIN MENU " \
        --no-collapse \
        --clear \
        --cancel-label "$hotkey + Start to Exit" \
        --menu "What CD based game system folders would you like scanned and CUE files created for?" $height $width 15 )

        choices=$("${selection[@]}" "${options[@]}" 2>&1 > /dev/tty1) || userExit

        for choice in $choices; do
          case $choice in
			*) python3 CueFileCreator.py "/$choice/"  
			   results=$(cat /dev/shm/CueFileCreator.log | uniq)
			   if [[ ! -z $results ]]; then
			     dialog --clear --backtitle "CUE File Creator" --title "The following CUE files have been created" \
			     --clear --msgbox "$results" $height $width 2>&1 > /dev/tty1
			     rm /dev/shm/CueFileCreator.log
			   else
			     dialog --clear --backtitle "CUE File Creator" --title "The following CUE files have been created" \
			     --clear --msgbox "There were no CUE files needed to be created for /$choice/" $height $width 2>&1 > /dev/tty1
			     rm /dev/shm/CueFileCreator.log
			   fi
			;;
          esac
        done
	done
}

# Main

main_menu
$ESUDO kill -9 $(pidof oga_controls)
$ESUDO systemctl restart oga_events &
