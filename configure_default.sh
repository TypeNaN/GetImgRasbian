#!/usr/bin/env bash
# -*- coding: UTF-8 -*-


################################################################################
# CONFIGURE
################################################################################
# Publice key for remote access to your raspberry pi
# AUTH_KEY="/path/to/publickey.pub"
AUTH_KEY=""


# raspberry pi host name
RPI_HOSTNAME="raspberrypi"


# WiFi
# static IP address
# Google DNS
AP_NICKNAME="Nick Name For Access point"
AP_BSSID="xx:xx:xx:xx:xx:xx"
AP_SSID="Your SSID Name"
AP_PASS="Your Password"
GETWAY="192.168.1"
ROUTER="${GETWAY}.1"                      # 192.168.1.1
STATIC_FIXIP="85"
STATIC_IP="${GETWAY}.${STATIC_FIXIP}"     # 192.168.1.85
STATIC_DNS="8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844"
HIDDEN_NETWORK="0"


COUNTRY="TH"


# Keyboard Layout
KBLAYOUT="us,th"


# Seconds Language
LANGUAGE="th_TH.UTF-8"
TIMEZONE="Asia/Bangkok"
