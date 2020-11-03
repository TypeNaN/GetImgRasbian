#!/usr/bin/env bash
# -*- coding: UTF-8 -*-


if [ ${EUID} -ne 0 ]; then
  whiptail \
  		--backtitle "ROOT PERMISSION" \
  		--title "PERMISSION DENIED" \
  		--msgbox "Please try again using the command\n\n\nsudo ${0}\nOr\nsudo ${0} new_user_name\n" 12 50 \
  		--ok-button "Close" \
  		--clear
  exit 1
fi

if ! [[ -z $1 ]]; then
    $NAME=$1
    id pi
    grep -E --color 'pi' /etc/passwd
    usermod -l $NAME pi
    usermod -d /home/$NAME/ -m $NAME
    groupmod -n $NAME pi
    id $NAME
    grep -E --color "${NAME}" /etc/passwd
    mv /etc/sudoers.d/010_pi-nopasswd /etc/sudoers.d/010_$NAME-nopasswd
    sed -i "s/pi/${NAME}/g" /etc/sudoers.d/010_$NAME-nopasswd
    sed -i "s/Pi/${NAME}/g" /home/$NAME/.bashrc
    chown $NAME:$NAME /home/$NAME/.bashrc
    chown -R $NAME:$NAME /home/$NAME/.ssh/
    if [[ -f "${WORKDIR}/${MIMG2}/etc/lightdm/lightdm.conf" ]]; then
      sed -i "s/^\(autologin-user\s*=\s*\).*\$/\1${NAME}/" /etc/lightdm/lightdm.conf
    fi
    # sed -i "s/#PermitEmptyPasswords no/PermitEmptyPasswords no/g" /etc/ssh/sshd_config
    sed -i "33iPermitRootLogin no\n" /etc/ssh/sshd_config
    rm -rf /root/.ssh
    rm -rf $0
    reboot
else
    NAME=$(
      whiptail \
        --clear \
        --backtitle "CHANGE NAME" \
        --title "CHANGE NAME" \
        --ok-button "SET NAME" \
        --cancel-button "CANCEL" \
        --inputbox "WHAT IS YOUR NAME?" 8 78 pi 3>&1 1>&2 2>&3)
    RES=$?
  	if [ $RES = 0 ]; then
        id pi
        grep -E --color 'pi' /etc/passwd
        usermod -l $NAME pi
        usermod -d /home/$NAME/ -m $NAME
        groupmod -n $NAME pi
        id $NAME
        grep -E --color "${NAME}" /etc/passwd
        mv /etc/sudoers.d/010_pi-nopasswd /etc/sudoers.d/010_$NAME-nopasswd
        sed -i "s/pi/${NAME}/g" /etc/sudoers.d/010_$NAME-nopasswd
        sed -i "s/Pi/${NAME}/g" /home/$NAME/.bashrc
        chown $NAME:$NAME /home/$NAME/.bashrc
        chown -R $NAME:$NAME /home/$NAME/.ssh/
        if [[ -f "${WORKDIR}/${MIMG2}/etc/lightdm/lightdm.conf" ]]; then
          sed -i "s/^\(autologin-user\s*=\s*\).*\$/\1${NAME}/" /etc/lightdm/lightdm.conf
        fi
        sed -i "33iPermitRootLogin no\n" /etc/ssh/sshd_config
        rm -rf /root/.ssh
        rm -rf $0
        reboot
    else
        echo "Cancel"
        exit 0
    fi
fi
