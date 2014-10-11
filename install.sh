#!/bin/bash

### Simple minded install script for
### FreeGeek Chicago by David Eads
### Updates by Brent Bandegar, Dee Newcum, James Slater, Alex Hanson

### Available on FreeGeek Chicago's github Account at http://git.io/Ool_Aw

### Import DISTRIB_CODENAME and DISTRIB_RELEASE
. /etc/lsb-release

### Get the integer part of $DISTRIB_RELEASE. Bash/test can't handle floating-point numbers.
DISTRIB_MAJOR_RELEASE=$(echo "scale=0; $DISTRIB_RELEASE/1" | bc)

echo "################################"
echo "#  FreeGeek Chicago Installer  #"
echo "################################"

# Default sources.list already has:
# <releasename> main restricted universe multiverse
# <releasename>-security main restricted universe multiverse
# <releasename>-updates main restricted

##################################
# Edits to /etc/apt/sources.list #
##################################

### Disable Source Repos
#
# Check to see if Source repos are set ON and turn OFF
if grep -q "deb-src#" /etc/apt/sources.list; then
    echo "# Already disabled source repositories"
else
    echo "* Commenting out source repositories -- we don't mirror them locally."
    sed -i 's/deb-src /#deb-src# /' /etc/apt/sources.list
fi

### METHOD 1? Add distrib-updates universe multiverse
#
# Figure out if this part of the script has been run already
#grep "${DISTRIB_CODENAME}-updates universe" /etc/apt/sources.list
#if (($? == 1)); then
#    echo "* Adding ${DISTRIB_CODENAME} updates line for universe and multiverse"
#    cp /etc/apt/sources.list /etc/apt/sources.list.backup
#    echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DISTRIB_CODENAME}-updates universe multiverse" >> /etc/apt/sources.list
#else
#    echo "# Already added universe and multiverse ${DISTRIB_CODENAME}-updates line to sources,"
#fi

### METHOD 2? Add distrib-updates universe multiverse
#
# Figure out if this part of the script has been run already
#if grep -q "${DISTRIB_CODENAME}-updates universe" /etc/apt/sources.list; then
#    echo "# Already added universe and multiverse ${DISTRIB_CODENAME}-updates line to sources,"
#else
#    echo "* Adding ${DISTRIB_CODENAME} updates line for universe and multiverse"
#    cp /etc/apt/sources.list /etc/apt/sources.list.backup
#    echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DISTRIB_CODENAME}-updates universe multiverse" >> /etc/apt/sources.list
#fi

### Disable and Remove Any Medibuntu Repos
#

if [ -e /etc/apt/sources.list.d/medibuntu.list ]; then
    echo "* Removing Medibuntu Repos."
    rm /etc/apt/sources.list.d/medibuntu*
else
    echo "# Already removed Medibuntu's libdvdcss repo."
fi

### Enable VideoLAN Repo for libdvdcss
#
# In the future call /usr/share/doc/libdvdread4/install-css.sh
#
if [ -e /etc/apt/sources.list.d/videolan.sources.list ]; then
    echo "# Already added libdvdcss repo, OK."
else
    echo "* Adding VideoLAN's libdvdcss repo, OK."
	echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.sources.list
#       echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.sources.list
	wget -O - http://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add - libdvdcss
fi


### Update everything
# We use dist-upgrade to ensure up-to-date kernels are installed
apt-get -y update && apt-get -y dist-upgrade

### Install FreeGeek's default packages
#
# Each package should have it's own apt-get line.
# If a package is not found or broken, the whole apt-get line is terminated.
#
# Add codecs / plugins that most people want
apt-get -y install ubuntu-restricted-extras
apt-get -y install totem-mozilla
apt-get -y install libdvdcss2
apt-get -y install non-free-codecs
apt-get -y install ttf-mgopen
apt-get -y install gcj-jre
apt-get -y install ca-certificates
apt-get -y install vlc
apt-get -y install mplayer
apt-get -y install chromium-browser
apt-get -y install hardinfo

# Add Pepper Flash Player support for Chromium
# Note that this temporarily downloads Chrome, and the plugin uses plugin APIs not provided in Firefox

if [ $(lsb_release -rs)='14.04' ]; then
	apt-get -y install pepperflashplugin-nonfree &&
	update-pepperflashplugin-nonfree --install
fi

# Add spanish language support
apt-get -y install language-pack-gnome-es language-pack-es

# Install nonfree firmware for Broadcom wireless cards and TV capture cards
apt-get -y install linux-firmware-nonfree

# Provided in ubuntu-restricted-extras: ttf-mscorefonts-installer flashplugin-installer
# Do we need these packages anymore?: exaile gecko-mediaplayer

# Install packages for specific Ubuntu versions
if [ $DISTRIB_MAJOR_RELEASE -ge 11 ]; then
    apt-get -y install libreoffice libreoffice-gtk
else
    apt-get -y install openoffice.org openoffice.org-gcj openoffice.org-gtk language-support-es
fi

### Remove conflicting default packages
#
apt-get -y remove gnumeric* abiword*

### Ensure installation completed without errors
#
apt-get -y install sl
wget -qO /usr/local/bin/nyancat "https://raw.githubusercontent.com/freegeekchicago/fgc-installscript/master/nyancat"
if [ -e "/usr/local/bin/nyancat" ] && [ -x "/usr/local/bin/nyancat" ]; then
	echo "Installation complete -- relax, and watch this NYAN CAT"
	/usr/local/bin/nyancat -nsf 37
else
	echo "Installation complete -- relax, and watch this STEAM LOCOMOTIVE"
	if [ $DISTRIB_MAJOR_RELEASE -ge 10 ]; then
    		/usr/games/sl
	else
    		sl
	fi
fi	
# Function that makes a prompt
ask() {
    while true; do
 
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi
 
        # Ask the question
        read -p "$1 [$prompt] " REPLY
 
        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi
 
        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
 
    done
}

# Ask for reboot
if ask "Do you want to reboot now?" N; then
    echo "Rebooting now."
    reboot
else
    exit 0
fi

## EOF
