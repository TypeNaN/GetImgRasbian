#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
################################################################################


################################################################################
# IMPORT CONFIGURE
################################################################################
source configure.sh


################################################################################
# PROCESS START HERE
################################################################################
time_start=$(date +"%s")
CReset="\033[0m"
CRed="\033[01;31m"
CGreen="\033[01;32m"
CYellow="\033[01;33m"
CCyan="\033[01;36m"


################################################################################
# FINISH
################################################################################
function finish() {
  if [[ -f "progress.txt" ]]; then cat progress.txt; fi
  if [[ -f "download.pid" ]]; then rm download.pid; fi
  umountimg
  chown -R 1000 ${WORKDIR}
  time_now=$(date +"%s")
  time_diff=$(($time_now-$time_start))
  echo "$(($time_diff / 3600)) hours $(($time_diff / 60)) minutes and $(($time_diff % 60)) seconds elapsed."
  echo "Good luck, bye :)"
}


trap finish SIGINT


################################################################################
# ROOT OR NOT
################################################################################
if [ ${EUID} -ne 0 ]; then
  whiptail \
		--backtitle "NEED PERMISSION" \
		--title "PERMISSION DENIED" \
		--msgbox "Please try again using the command\n\n\nsudo ${0}\n" 10 50 \
		--ok-button "Agree" \
		--clear
  exit 0
fi


################################################################################
# GLOBAL VALUES
################################################################################
# Working directory
# This file container is used by default.
WORKDIR="$(dirname ${0})"
mkdir -p ${WORKDIR}
cd ${WORKDIR}
echo -e "Working directory  : ${CGreen}${WORKDIR}${CReset}"


DEVICE=""
CURLPID=""
OS=""
OSIMG=""
OSDIR="${WORKDIR}/os_img"
MIMG1="img1"
MIMG2="img2"


################################################################################
# CURL IDLE OR BUSY
################################################################################
if [[ -f "progress.txt" ]]; then rm progress.txt; fi
if [[ -f "download.pid" ]]; then
  proc=$(ps aux | grep -v grep | grep -e "curl" | awk -F " " '{print $2 }')
  lastpid=$(cat download.pid)
  echo -e "Curl PID           : ${CGreen}${proc}${CReset}"
  if [[ "${proc}" ]]; then
    echo -e "Curl               : ${CRed}BUSY${CReset}"
    if [[ "${proc}" -eq "${lastpid}" ]]; then
      echo -e "Curl               : ${CRed}-eq lastpid ${lastpid}${CReset}"
      whiptail \
    		--backtitle "CURL" \
    		--title "CURL LAST PROCESS NOT TERMINATE" \
    		--msgbox "Please terminate Curl before\n\n\nkill \"${proc}\"\n" 10 50 \
    		--ok-button "Agree" \
    		--clear
    else
      echo -e "Curl               : ${CGreen}IDLE${CReset}"
      whiptail \
    		--backtitle "CURL" \
    		--title "CURL IS USED BY ANOTHOR" \
    		--msgbox "Please terminate Curl before\n\n\nkill \"${proc}\"\n" 10 50 \
    		--ok-button "Agree" \
    		--clear
    fi
    finish
    exit 0
  else
    echo -e "Curl               : ${CGreen}IDLE${CReset}"
  fi
fi


################################################################################
# MOUNT IMG
################################################################################
function mountimg() {
  mkdir -p $MIMG1 $MIMG2
  blockimg1=($(fdisk -lu ${OSDIR}/${OSIMG} | grep img1 | awk -F " " '{print $2,$4}'))
  blockimg2=($(fdisk -lu ${OSDIR}/${OSIMG} | grep img2 | awk -F " " '{print $2,$4}'))
  mount ${OSDIR}/${OSIMG} -o loop,offset=$(( 512 * ${blockimg1[0]} )),sizelimit=$(( 512 * ${blockimg1[1]} )) $MIMG1
  mount ${OSDIR}/${OSIMG} -o loop,offset=$(( 512 * ${blockimg2[0]} )),sizelimit=$(( 512 * ${blockimg2[1]} )) $MIMG2
}


################################################################################
# UMOUNT IMG
################################################################################
function umountimg() {
  MPOINT=($(df -h --output=target | grep ${WORKDIR} | grep img))
  if ! [[ -f "${MPOINT}" ]]; then
    for mp in ${MPOINT[@]} ; do
      echo "umount $mp"
      umount -f $mp
    done
  fi
  rm -rf $MIMG1 $MIMG2
  sync
}


################################################################################
# CHOOSE YOUR DEVICE
################################################################################
function whatdevice() {
  # REF https://unix.stackexchange.com/a/60335
  USBKEYS=($(
    grep -Hv ^0$ /sys/block/*/removable |
    sed s/removable:.*$/device\\/uevent/ |
    xargs grep -H ^DRIVER=sd |
    sed s/device.uevent.*$/size/ |
    xargs grep -Hv ^0$ |
    cut -d / -f 4
  ))
  case ${#USBKEYS[@]} in
    0 ) echo "No USB Stick found" ;;
    1 ) DEVICE=$USBKEYS ;;
    * ) DEVICE=$(
          bash -c "$(echo -n whiptail \
            --clear \
            --backtitle \"SETUP RASPBERRY PI OS\" \
            --title \"CHOOSE DEVICE\" \
            --ok-button \"CHOOSE\" \
            --cancel-button \"CANCEL\" \
            --menu \"Your data maybe lost\\nPlease [ double \| triple ] check\" 14 85 4 ;
              for dev in ${USBKEYS[@]} ; do
                echo -n \ $dev \"$(sed -e s/\ *$//g </sys/block/$dev/device/model)\" ;
              done
          )" 3>&1 1>&2 2>&3) ;;
  esac
  echo -e "device             : ${CYellow}/dev/${DEVICE}${CReset}"
}


################################################################################
# MAIN PROCESS
################################################################################
function main() {
  MAIN_MENU=$(
    whiptail \
      --clear \
  		--backtitle "SETUP RASPBERRY PI OS" \
  		--title "CHOOSE RASPBERRY PI OS" \
  		--ok-button "CHOOSE" \
  		--cancel-button "CANCEL" \
  		--menu "INSTALL RASPBERRY PI OS TO /DEV/${DEVICE^^}" 14 85 4 \
  			"full" "RASPBERRY PI OS with desktop and recommended software   " \
  			"mini" "RASPBERRY PI OS with desktop" \
        "lite" "RASPBERRY PI OS with console" 3>&1 1>&2 2>&3)
  local RES=$?
	case ${RES} in
		0)
			case ${MAIN_MENU} in
				"full")
          OS="raspios_full_armhf_latest"
          OSSHA256="1"
          existimg
					checkimg
					;;
				"mini")
          OS="raspios_armhf_latest"
          OSSHA256="2"
          existimg
					checkimg
					;;
				"lite")
          OS="raspios_lite_armhf_latest"
          OSSHA256="3"
          existimg
					checkimg
					;;
			esac
			;;
		1)
      finish
			exit 0
			;;
		255)
      finish
			exit 0
      ;;
	esac
}


################################################################################
# FILE IMG EXIST OR NOT
################################################################################
function existimg() {
  # LISTDESKFULL=($(find "${OSDIR}" -type f -iname "*full.img" | sed -r "s/${OSDIR}\///g"))
  # CONSOLE=$(find "${OSDIR}" -type f -iname "*.img" | sed -r "s/\.\///g" | grep lite)
  # DESKMINI=$(find "${OSDIR}" -type f -iname "*.img" | sed -r "s/\.\///g")
  # if [[ -f "${DESKFULL}" ]]; then DESKMINI=$(echo ${DESKMINI} | sed -r "s/${DESKFULL}//g"); fi
  # if [[ -f "${CONSOLE}" ]]; then DESKMINI=$(echo ${DESKMINI} | sed -r "s/${CONSOLE}//g"); fi
  # if [[ "${OSSHA256}" == "1" ]]; then
  #   OSIMG=${DESKFULL}
  # elif [[ "${OSSHA256}" == "2" ]]; then
  #   shopt -s extglob
  #   DESKMINI=${DESKMINI##*( )} # Trim leading whitespaces
  #   DESKMINI=${DESKMINI%%*( )} # Trim trailing whitespaces
  #   OSIMG=${DESKMINI}
  # else
  #   OSIMG=${CONSOLE}
  # fi
  # echo -e "OSDIR              : ${CGreen}${OSDIR}${CReset}"
  # echo -e "DESKFULL           : ${CGreen}${DESKFULL}${CReset}"
  # echo -e "DESKMINI           : ${CGreen}${DESKMINI}${CReset}"
  # echo -e "CONSOLE            : ${CGreen}${CONSOLE}${CReset}"
  # echo -e "OSIMG              : ${CGreen}${OSIMG}${CReset}"

  echo -e "OSDIR              : ${CGreen}${OSDIR}${CReset}"
  OSDIRNAME=$(echo ${OSDIR} | sed -r "s/${WORKDIR}\///g")
  if [[ "${OSSHA256}" == "1" ]]; then
    LISTDESKFULL=($(find "${OSDIR}" -type f -iname "*full.img" | sed -r "s/\.\///g" | sed -r "s/${OSDIRNAME}\///g"))
    case ${#LISTDESKFULL[@]} in
      0 ) echo -e "DESKFULL           : ${CRed}Not found${CReset}" ;;
      1 ) OSIMG=$LISTDESKFULL ;;
      * ) OSIMG=$(
            bash -c "$(echo -n whiptail \
              --clear \
              --backtitle \"SETUP RASPBERRY PI OS\" \
              --title \"CHOOSE OS\" \
              --ok-button \"CHOOSE\" \
              --cancel-button \"CANCEL\" \
              --menu \"Your data maybe lost\\nPlease [ double \| triple ] check\" 14 85 4 ;
                for img in ${LISTDESKFULL[@]} ; do
                  echo -n \ $img \"\" ;
                done
            )" 3>&1 1>&2 2>&3) ;;
    esac
  elif [[ "${OSSHA256}" == "2" ]]; then
    DESKMINI=($(find "${OSDIR}" -type f \( -iname "*.img" ! -iname "*full.img" ! -iname "*lite.img" \) | sed -r "s/\.\///g" | sed -r "s/${OSDIRNAME}\///g"))
    case ${#DESKMINI[@]} in
      0 ) echo -e "DESKMINI           : ${CRed}Not found${CReset}" ;;
      1 ) OSIMG=$DESKMINI ;;
      * ) OSIMG=$(
            bash -c "$(echo -n whiptail \
              --clear \
              --backtitle \"SETUP RASPBERRY PI OS\" \
              --title \"CHOOSE OS\" \
              --ok-button \"CHOOSE\" \
              --cancel-button \"CANCEL\" \
              --menu \"Your data maybe lost\\nPlease [ double \| triple ] check\" 14 85 4 ;
                for img in ${DESKMINI[@]} ; do
                  echo -n \ $img \"\" ;
                done
            )" 3>&1 1>&2 2>&3) ;;
    esac
  else
    LISTCONSOLE=($(find "${OSDIR}" -type f -iname "*lite.img" | sed -r "s/\.\///g" | sed -r "s/${OSDIRNAME}\///g"))
    case ${#LISTCONSOLE[@]} in
      0 ) echo -e "CONSOLE            : ${CRed}Not found${CReset}" ;;
      1 ) OSIMG=$LISTCONSOLE ;;
      * ) OSIMG=$(
            bash -c "$(echo -n whiptail \
              --clear \
              --backtitle \"SETUP RASPBERRY PI OS\" \
              --title \"CHOOSE OS\" \
              --ok-button \"CHOOSE\" \
              --cancel-button \"CANCEL\" \
              --menu \"Your data maybe lost\\nPlease [ double \| triple ] check\" 14 85 4 ;
                for img in ${LISTCONSOLE[@]} ; do
                  echo -n \ $img \"\" ;
                done
            )" 3>&1 1>&2 2>&3) ;;
    esac
  fi
  echo -e "OSIMG              : ${CGreen}${OSIMG}${CReset}"
}


################################################################################
# DIFF FILE IMG
################################################################################
function diffimg() {
  echo -e "Query SHA-256 from : ${CCyan}https://www.raspberrypi.org/downloads/raspbian/${CReset}"
  CHECKSHA256=$(curl -sL https://www.raspberrypi.org/downloads/raspbian/ | grep "SHA-256:" | awk -F "<strong>|</strong>" '{print $2 }' | sed -n ${OSSHA256}p)
  echo -e "SHA256SUM file     : ${CGreen}${OS}.zip${CReset}"
  FILESHA256=$(sha256sum "${OSDIR}/${OS}.zip" | awk -F " " '{print $1 }')
  echo -e "WEB  SHA-256       : ${CYellow}${CHECKSHA256}${CReset}"
  echo -e "FILE SHA-256       : ${CYellow}${FILESHA256}${CReset}"
  if [[ "${FILESHA256}" == "${CHECKSHA256}" ]]; then
    echo -e "WEB VS FILE        : ${CGreen}Identical${CReset}"
    return 0
  else
    echo -e "WEB VS FILE        : ${CRed}Differ${CReset}"
    return 1
  fi
}


################################################################################
# CHECK SUM IMG
################################################################################
function checkimg() {
  if [[ -f "${OSDIR}/${OSIMG}" ]]; then
    echo -e "Found              : ${CGreen}${OSDIR}/${OSIMG}${CReset}"
    if [[ -f "${OSDIR}/${OS}.zip" ]]; then
      echo -e "Found              : ${CGreen}${OSDIR}/${OS}.zip${CReset}"
      USEIMG_MENU=$(
        whiptail \
          --clear \
      		--backtitle "SETUP RASPBERRY PI OS" \
      		--title "CHOOSE RASPBERRY PI OS" \
      		--ok-button "CHOOSE" \
      		--cancel-button "CANCEL" \
      		--menu "RASPBERRY PI OS" 14 85 4 \
      			"USE CURRENT" "${OSIMG}   " \
            "EXTRACT" "${OS}.zip   " \
      			"NEW DOWNLOAD" "${OS}.zip   " 3>&1 1>&2 2>&3)
      local RES=$?
    	case ${RES} in
    		0)
    			case ${USEIMG_MENU} in
    				"USE CURRENT")
              usethisimg
    					;;
    				"EXTRACT")
              extractthiszip
    					;;
    				"NEW DOWNLOAD")
              download
              extractthiszip
    					;;
    			esac
    			;;
    		1)
          finish
    			exit 0
    			;;
    		255)
          finish
    			exit 0
          ;;
    	esac
    else
      echo -e "Not Found          : ${CGreen}${OSDIR}/${OS}.zip${CReset}"
      USEIMG_MENU=$(
        whiptail \
          --clear \
      		--backtitle "SETUP RASPBERRY PI OS" \
      		--title "CHOOSE RASPBERRY PI OS" \
      		--ok-button "CHOOSE" \
      		--cancel-button "CANCEL" \
      		--menu "RASPBERRY PI OS" 14 85 4 \
      			"USE CURRENT" "${OSIMG}   " \
      			"NEW DOWNLOAD" "${OS}.zip   " 3>&1 1>&2 2>&3)
      local RES=$?
    	case ${RES} in
    		0)
    			case ${USEIMG_MENU} in
    				"USE CURRENT")
              usethisimg
    					;;
    				"NEW DOWNLOAD")
              download
              extractthiszip
    					;;
    			esac
    			;;
    		1)
          finish
    			exit 0
    			;;
    		255)
          finish
    			exit 0
          ;;
    	esac
    fi
  else
    echo -e "Not Found          : ${CGreen}${OSDIR}/${OSIMG}${CReset}"
    if [[ -f "${OSDIR}/${OS}.zip" ]]; then
      echo -e "Found              : ${CGreen}${OSDIR}/${OS}.zip${CReset}"
      USEIMG_MENU=$(
        whiptail \
          --clear \
      		--backtitle "SETUP RASPBERRY PI OS" \
      		--title "CHOOSE RASPBERRY PI OS" \
      		--ok-button "CHOOSE" \
      		--cancel-button "CANCEL" \
      		--menu "RASPBERRY PI OS" 14 85 4 \
            "EXTRACT" "${OS}.zip   " \
      			"NEW DOWNLOAD" "${OS}.zip   " 3>&1 1>&2 2>&3)
      local RES=$?
    	case ${RES} in
    		0)
    			case ${USEIMG_MENU} in
    				"EXTRACT")
              extractthiszip
    					;;
    				"NEW DOWNLOAD")
              download
              extractthiszip
    					;;
    			esac
    			;;
    		1)
          finish
    			exit 0
    			;;
    		255)
          finish
    			exit 0
          ;;
    	esac
    else
      echo -e "Not Found          : ${CGreen}${OSDIR}/${OS}.zip${CReset}"
      download
      extractthiszip
    fi
  fi
}


################################################################################
# USE THIS IMG
################################################################################
function usethisimg() {
  echo "USE CURRENT ${USEIMG_MENU}"
  echo -e "\n\n${CGreen}!!! use current ${OSIMG} !!!${CReset}\n\n"
  burnimg
}


################################################################################
# USE THIS IMG
################################################################################
function extractthiszip() {
  echo -e "\n\n${CGreen}!!! Extract ${OS} and install !!!${CReset}\n\n"
  diffimg
  local RES=$?
  if [[ "${RES}" -eq "0" ]]; then
    echo -e "${CGreen}Extracting ${OS}....${CReset}"
    OSIMG=$(unzip -o "${OSDIR}/${OS}.zip" -d "${OSDIR}/" | sed -n 2p | awk -F "${OSDIR}/" '{print $2}')
    echo "extractthiszip  as ${OSIMG}"
    imgidentical
  else
    echo -e "${CGreen}Differ ${OS}....${CReset}"
    rm "${OSDIR}/${OS}.zip"
    imgdiffer
  fi
}


################################################################################
# IMG IDENTICAL
################################################################################
function imgidentical() {
  echo -e "${CGreen}Installing ${OSIMG}....${CReset}"
  mountimg
  editimg
  umountimg
  burnimg
}


################################################################################
# IMG IDENTICAL
################################################################################
function imgdiffer() {
  echo -e "\n\n${CRed}!!! Delete .img and download ${OS} again !!!${CReset}\n\n"
  USEIMG_MENU=$(
    whiptail \
      --clear \
      --backtitle "SETUP RASPBERRY PI OS" \
      --title "DOWNLOAD RASPBERRY PI OS AGAIN" \
      --ok-button "OK" \
      --cancel-button "CANCEL" \
      --menu "RASPBERRY PI OS : ${OS}.zip \nCheck sum don't match" 14 85 4 \
        "DOWNLOAD AGAIN" "${OS}.zip   " 3>&1 1>&2 2>&3)
  local RES=$?
  case ${RES} in
    0)
      case ${USEIMG_MENU} in
        "DOWNLOAD AGAIN")
          download
          extractthiszip
          ;;
      esac
      ;;
    1)
      finish
      exit 0
      ;;
    255)
      finish
      exit 0
      ;;
  esac
}


################################################################################
# DOWNLOAD IMG
################################################################################
function download() {
  echo "Downloading.. ${OS}"
  proc=$(ps aux | grep -v grep | grep -e "curl")
  if [[ "$proc" == "" ]]; then
    curl --progress-bar -L -o ${OSDIR}/${OS}.zip https://downloads.raspberrypi.org/${OS} 2>progress.txt &
    CURLPID=$!
    echo $CURLPID > download.pid
    sleep 5
  fi
  {
    percentage="0"
    while (true); do
        proc=$(ps aux | grep -v grep | grep -e "${CURLPID}")
        percentage=$( echo -ne "$( tr $'\r' $'\n' < progress.txt | tail -n 1 | sed -r 's/^[# ]+//g;' | sed -r 's/%+//g;' ) \r"; )
        percentage=${percentage%%.*}
        if [[ ! "$percentage" =~ ^[0-9]+$ ]]; then
          sleep 5
          proc=$(ps aux | grep -v grep | grep -e "${CURLPID}")
          if [[ -z "$proc" ]]; then
            curl --progress-bar -L -o ${OSDIR}/${OS}.zip -C - https://downloads.raspberrypi.org/${OS} 2>progress.txt &
            CURLPID=$!
            echo $CURLPID > download.pid
            sleep 5
            continue
          fi
        fi
        if [[ -z "$proc" ]] && [[ "$percentage" -eq "0" ]]; then
          break
        elif [[ -z "$proc" ]] && [[ "$percentage" -eq "100" ]]; then
          echo $percentage
          sleep 1
          break
        elif [[ -z "$proc" ]]; then
          finish
          exit 1
        else
          read -t 0.1 -N 1 input
          if [[ $input == 'q' ]] || [[ $input == "Q" ]];then
            kill $CURLPID
            break;
          fi
          echo $percentage
        fi

    done
  } | whiptail \
    --backtitle "SETUP RASPBERRY PI OS" \
    --title "DOWNLOAD RASPBERRY PI OS" \
    --gauge "Please wait while we are downloading.....\nhttps://downloads.raspberrypi.org/${OS}\nPress Q for Abort" 7 60 0 \
    --clear
}


################################################################################
# EDIT IMG
################################################################################
function editimg() {
  editbashrc
  if ! [[ -z "${AUTH_KEY}" ]]; then
    editauthorize
  fi
  edithostname
  editdhcpcd
  editwpa
  setup_language_region         # Don't work, Will be overwritten at first boot
  setup_keyboard
  setup_desktop_config
  setup_disable_blank_screen
  setup_autologin_user
  add_your_scripts
  sync
  sleep 3
}


function editbashrc() {
  echo -e "Edit               : ${CGreen}~/.bashrc${CReset}"
  sed -i "60d" ./${MIMG2}/home/pi/.bashrc
  sed -i "60i\ \ \ \ PS1=\'\${debian_chroot:+(\$debian_chroot)}\\\[\\\033[01;32m\\\]\\\n\'\n \
  PS1+=\'┣—┫ \\\[\\\033[01;31m\\\]\\\h \\\[\\\033[01;32m\\\]: \\\[\\\033[01;34m\\\]\\\w\\\[\\\033[01;32m\\\]\\\n\'\n \
  PS1+=\'└—▶ \\\[\\\033[93m\\\]\$ \\\[\\\033[0m\\\]\'" ./${MIMG2}/home/pi/.bashrc
  sed -i '71d' ./${MIMG2}/home/pi/.bashrc
  sed -i "71i\ \ \ \ PS1=\"\\\[\\\e]0\;\\\l Pi\\\a\\\]\$PS1\"" ./${MIMG2}/home/pi/.bashrc
}


function editauthorize() {
  echo -e "Setup              : ${CGreen}Authorizetion${CReset}"
  mkdir -p ${WORKDIR}/${MIMG2}/root/.ssh/
  cat ${AUTH_KEY} > ${WORKDIR}/${MIMG2}/root/.ssh/authorized_keys
  mkdir -p ${WORKDIR}/${MIMG2}/home/pi/.ssh/
  cat ${AUTH_KEY} > ${WORKDIR}/${MIMG2}/home/pi/.ssh/authorized_keys
  chown -R 1000 ${WORKDIR}/${MIMG2}/home/pi/.ssh
  sed -i "41iAuthorizedKeysFile     .ssh/authorized_keys" ${WORKDIR}/${MIMG2}/etc/ssh/sshd_config
  sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/g" ${WORKDIR}/${MIMG2}/etc/ssh/sshd_config
  sed -i "s/#PermitEmptyPasswords no/PermitEmptyPasswords no/g" ${WORKDIR}/${MIMG2}/etc/ssh/sshd_config
}


function edithostname() {
  echo -e "Edit               : ${CGreen}Hostname${CReset}"
  echo ${RPI_HOSTNAME} > ${WORKDIR}/${MIMG2}/etc/hostname
  sed -i "s/raspberrypi/${RPI_HOSTNAME}/g" ${WORKDIR}/${MIMG2}/etc/hosts
}


function editdhcpcd() {
  echo -e "Edit               : ${CGreen}/etc/dhcpcd${CReset}"
  echo -e "\n\nSSID ${AP_SSID}" >> ${WORKDIR}/${MIMG2}/etc/dhcpcd.conf
  echo "inform ${STATIC_IP}/24" >> ${WORKDIR}/${MIMG2}/etc/dhcpcd.conf
  echo "static routers=${ROUTER}" >> ${WORKDIR}/${MIMG2}/etc/dhcpcd.conf
  echo "static broadcast_address=${GETWAY}.255" >> ${WORKDIR}/${MIMG2}/etc/dhcpcd.conf
  echo "static domain_name_servers=${STATIC_DNS}" >> ${WORKDIR}/${MIMG2}/etc/dhcpcd.conf
}


function editwpa() {
  echo -e "Edit               : ${CGreen}WiFi${CReset}"
  echo "country=${COUNTRY}" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo -e "\nnetwork={" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	id_str=\"${AP_NICKNAME}\"" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	bssid=${AP_BSSID}" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	ssid=\"${AP_SSID}\"" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	psk=\"${AP_PASS}\"" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  if [[ "${HIDDEN_NETWORK}" -eq "1" ]]; then
    echo "	scan_ssid=1" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  else
    echo "	scan_ssid=0" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  fi
  echo "	proto=RSN" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	key_mgmt=WPA-PSK" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	group=CCMP TKIP" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	pairwise=CCMP TKIP" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "	priority=1" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
  echo "}" >> ${WORKDIR}/${MIMG2}/etc/wpa_supplicant/wpa_supplicant.conf
}


function setup_language_region() {
  echo -e "Setup              : ${CGreen}Language & Region${CReset}"
  sed -i "s/^\(LANG\s*=\s*\).*\$/\1en_GB.UTF-8/" ${WORKDIR}/${MIMG2}/etc/default/locale
  echo "LANGUAGE=en_GB.UTF-8" >> ${WORKDIR}/${MIMG2}/etc/default/locale
  echo "LC_ALL=en_GB.UTF-8" >> ${WORKDIR}/${MIMG2}/etc/default/locale
  sed -i '/^#.* th_TH.UTF-8 /s/^#\ //' ${WORKDIR}/${MIMG2}/etc/locale.gen
  echo -e "Setup              : ${CGreen}Time Zone ${TIMEZONE}${CReset}"
  echo "${TIMEZONE}" > ${WORKDIR}/${MIMG2}/etc/timezone   # wrong time.
                                                          # Need sudo raspi-config to setup again, why?
}


function setup_keyboard() {
  echo -e "Setup              : ${CGreen}Keyboard${CReset}"
  sed -i "s/^\(XKBMODEL\s*=\s*\).*\$/\1pc105/" ${WORKDIR}/${MIMG2}/etc/default/keyboard
  sed -i "s/^\(XKBLAYOUT\s*=\s*\).*\$/\1${KBLAYOUT}/" ${WORKDIR}/${MIMG2}/etc/default/keyboard
  sed -i "s/^\(XKBVARIANT\s*=\s*\).*\$/\1,/" ${WORKDIR}/${MIMG2}/etc/default/keyboard
  sed -i "s/^\(XKBOPTIONS\s*=\s*\).*\$/\1grp:alt_shift_toggle,terminate:ctrl_alt_bksp,grp_led:scroll/" ${WORKDIR}/${MIMG2}/etc/default/keyboard
  sed -i "s/^\(BACKSPACE\s*=\s*\).*\$/\1guess/" ${WORKDIR}/${MIMG2}/etc/default/keyboard
}


function setup_desktop_config() {
  if [[ -d "${WORKDIR}/${MIMG2}/usr/share/rpd-wallpaper" ]]; then
    echo -e "Copy               : ${CGreen}Wallpaper${CReset}"
    cp ${WORKDIR}/lain_teddy_bear.jpg ${WORKDIR}/${MIMG2}/usr/share/rpd-wallpaper/
  fi
  if [[ -f "${WORKDIR}/${MIMG2}/etc/lightdm/pi-greeter.conf" ]]; then
    echo -e "Setup              : ${CGreen}Login Screen${CReset}"
    sed -i "s/^\(desktop_bg\s*=\s*\).*\$/\1#0f0f0f0f0f0f/" ${WORKDIR}/${MIMG2}/etc/lightdm/pi-greeter.conf
    sed -i "s/^\(wallpaper\s*=\s*\).*\$/\1\/usr\/share\/rpd-wallpaper\/lain_teddy_bear.jpg/" ${WORKDIR}/${MIMG2}/etc/lightdm/pi-greeter.conf
    sed -i "s/^\(gtk-font-name\s*=\s*\).*\$/\1PibotoLt 8/" ${WORKDIR}/${MIMG2}/etc/lightdm/pi-greeter.conf
    cp -R ${WORKDIR}/.config ${WORKDIR}/${MIMG2}/home/pi/.config
    chown -R 1000:1000 ${WORKDIR}/${MIMG2}/home/pi/.config
  fi
}


function setup_disable_blank_screen() {
  if [[ -f "${WORKDIR}/${MIMG2}/etc/lightdm/lightdm.conf" ]]; then
    echo -e "Setup              : ${CGreen}Disable Blank Screen${CReset}"
    sed -i "132ixserver-command=X -s 0 dpms" ${WORKDIR}/${MIMG2}/etc/lightdm/lightdm.conf
  fi
}


function setup_autologin_user() {
  if [[ -f "${WORKDIR}/${MIMG2}/etc/lightdm/lightdm.conf" ]]; then
    echo -e "Setup              : ${CGreen}User Name For Auto Login${CRed}${CReset}"
    echo -e "\n\n${CGreen}!!! Auto login by default for desktop !!!${CReset}\n\n"
    # don't work until change user name
    # sed -i "s/^\(autologin-user\s*=\s*\).*\$/\1username/" ${WORKDIR}/${MIMG2}/etc/lightdm/lightdm.conf
  fi
}


function add_your_scripts() {
  echo -e "Add                : ${CGreen}Your Scripts${CReset}"
  cp -R ${WORKDIR}/your_scripts ${WORKDIR}/${MIMG2}/home/pi/your_scripts
  chown -R 1000:1000 ${WORKDIR}/${MIMG2}/home/pi/your_scripts
  cp ${WORKDIR}/rename-id-1000.sh ${WORKDIR}/${MIMG2}/root/
}


function burnimg() {
  if ! [[ -z "${DEVICE}" ]]; then
    echo -e "\n\n${CGreen}Let's install ${CYellow}/dev/${DEVICE}${CReset}\n\n"
    PARTITIONS=$(mount | grep ${DEVICE} | awk -F " " '{print $1}')
    for sdxy in ${PARTITIONS[@]} ; do
      echo "umount $sdxy"
      umount -f $sdxy
    done
    sync
    dd bs=4M if=${OSDIR}/${OSIMG} of=/dev/${DEVICE} status=progress conv=noerror,fsync
  fi
}

umountimg
whatdevice
if ! [[ -z "${DEVICE}" ]]; then
  main
fi
finish

exit 0
