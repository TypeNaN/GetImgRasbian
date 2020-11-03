# GetRasPiOS
Auto setup Raspberry Pi OS for Raspberry Pi Board from Ubuntu or other Linux Distribution

#### Requirement
~~~
  - Personal computer run Linux distribution (Ubuntu or Debian)
  - Raspberry pi single board computer
  - MicroSD card
  - Internet connection

~~~

#### Dependency
~~~bash
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y git
~~~

#### Clone -> GetRasPiOS
~~~bash
  git clone https://github.com/TypeNaN/GetRasPiOS.git
  cd GetRasPiOS
~~~

#### Edit -> Configure
~~~bash
  cp configure_default.sh configure.sh
  nano configure.sh
~~~

~~~bash
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
~~~

#### Now Run
~~~bash
  sudo ./setup.sh
~~~



---

# MIT License

Copyright (c) 2020 TypeNaN

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
