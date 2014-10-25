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

#############################################
# Edit /etc/update-manager/release-upgrades #
#############################################

# Check to see if Source repos are set ON and turn OFF
if grep -q "Prompt=never" /etc/update-manager/release-upgrades; then
    echo "# Release Upgrades set to 'never'"
else
    echo "* Setting Release Upgrades to 'never'"
    sed -i 's/Prompt=lts/Prompt=never/' /etc/update-manager/release-upgrades
fi


#######################
# Add/Remove Packages #
#######################

### Update everything
# We use dist-upgrade to ensure up-to-date kernels are installed
apt-get -y update && apt-get -y dist-upgrade

# Each package should have it's own apt-get line.
# If a package is not found or broken, the whole apt-get line is terminated.


### Packages for Trusty (14.04) ###
###################################

# Add Pepper Flash Player support for Chromium
# Note that this temporarily downloads Chrome, and the plugin uses plugin APIs not provided in Firefox
if [ $(lsb_release -rs) = '14.04' ]; then
    echo "* Customizing Trusty packages"
    apt-get -y install pepperflashplugin-nonfree &&
    update-pepperflashplugin-nonfree --install
    apt-get -y install libreoffice
    apt-get -y install fonts-mgopen
fi

# Kubuntu 14.04 Specific Packages
if [ $(dpkg-query -W -f='${Status}' kubuntu-desktop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "* Customizing Trusty-Kubuntu packages."
    apt-get -y install software-center
    apt-get -y install kdewallpapers
    apt-get -y install kubuntu-restricted-extras
    apt-get -y autoremove muon muon-updater muon-discover
fi

# Xubuntu 14.04 Specific Packages
if [ $(dpkg-query -W -f='${Status}' xubuntu-desktop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "* Customizing Trusty-Xubuntu packages."
    apt-get -y install xubuntu-restricted-extras
    apt-get -y remove gnumeric* abiword*
fi

###
### Packages for Precise (12.04) ###
####################################

if [ $(lsb_release -rs)='12.04' ]; then
    echo "* Customizing Precise packages."
    apt-get -y install ttf-mgopen
fi

# Xubuntu 14.04 Specific Packages
if [ $(dpkg-query -W -f='${Status}' xubuntu-desktop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "* Customizing Precise-Xubuntu packages."
    apt-get -y install xubuntu-restricted-extras
    apt-get -y remove gnumeric* abiword*
fi



###############
### Packages for All Releases
###############

# Add codecs / plugins that most people want
apt-get -y install ubuntu-restricted-extras
apt-get -y install non-free-codecs
apt-get -y install libdvdcss2

# Add design / graphics programs
apt-get -y install gimp
apt-get -y install krita
apt-get -y install inkscape

# Add VLC and mplayer to play all multimedia
apt-get -y install vlc
apt-get -y install mplayer
apt-get -y install totem-mozilla
# Need to justify installation of mplayer and totem-mozilla

# Misc Packages. Need to justify installation of each.
apt-get -y install gcj-jre
apt-get -y install ca-certificates
apt-get -y install chromium-browser
# Also install Chrome?
apt-get -y install hardinfo

# Add spanish language support
apt-get -y install language-pack-es
apt-get -y install language-pack-gnome-es

# Install nonfree firmware for Broadcom wireless cards and TV capture cards
apt-get -y install linux-firmware-nonfree


#################################
# Install and Run sl or nyancat #
#################################
# Ensure installation completed without errors

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

##################
# Ask for reboot #
##################

if ask "Do you want to reboot now?" N; then
    echo "Rebooting now."
    reboot
else
    exit 0
fi

## EOF
