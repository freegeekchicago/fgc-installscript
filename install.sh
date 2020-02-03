#!/bin/bash

### Simple minded install script for
### FreeGeek Chicago by David Eads
### Updates by Brent Bandegar, Dee Newcum, James Slater, Alex Hanson, Benjamin Mintz, Duncan Steenburgh

### Available on FreeGeek` Chicago's github Account at http://git.io/Ool_Aw

### Check if we have root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Try sudo ./install.txt"
   exit 1
fi

echo "################################"
echo "#  FreeGeek Chicago Installer  #"
echo "################################"

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

log_pretty() {
	MSG=$1

	LIGHT_BLUE="1;34"
	LIGHT_BLUE_FORMAT_STR="\033[${LIGHT_BLUE}m"
	NO_COLOR_FORMAT_STR="\033[0m"
	printf "${LIGHT_BLUE_FORMAT_STR}"
	printf "##############################################\n"
	printf "%s\n" "$MSG"
	printf "##############################################\n"
	printf "${NO_COLOR_FORMAT_STR}"
}

#######################
# Add/Remove Packages #
#######################

### Update everything
# We use full-upgrade to ensure up-to-date kernels are installed
log_pretty "Updating everything"
apt-get update
apt-get dist-upgrade -y
dpkg --configure -a
apt-get install -f -y
apt-get update
apt-get dist-upgrade -y

# On mint, dist-upgrade doesn't always update everything. 
# If we're on mint, be sure to run the mintupdate-tool just in case
# Note: mintupdate-tool is deprecated at of mint 19 in favor of mintupdate-cli
# Once we phase out 18.3, we should use mindupdate-cli instead.
if [ -x "$(command -v mintupdate-tool)" ]; then
    log_pretty 'Linux mint install detected. Running mintupdate-tool'
    # If there is an update available for mintupdate-tool itself, it ignores all other arguments and only updates itself.
    # Running it twice gets around this quirk.
    mintupdate-tool upgrade -ry  
    mintupdate-tool upgrade -rksy -l 12345 --install-recommends
fi

### Packages for Linux Mint 18.3 ###
####################################
if [ $(lsb_release -rs) = '18.3' ] | [ $(lsb_release -rs) = '19.1' ]; then
    log_pretty "Mint detected, running additional configuration steps for mint"
    # Volman controls autoplay settings for xfce
    if [ $(dpkg-query -W -f='${Status}' thunar-volman 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "Setting up autoplay for linux mint"
        # Note: A reboot or logout/login is required for these settings to take effect.
        xfconf-query -c thunar-volman -n -t string -p /autoplay-audio-cds/command -s "/usr/bin/vlc cdda://"
        xfconf-query -c thunar-volman -n -t string -p /autoplay-video-cds/command -s "/usr/bin/vlc dvd://"
    fi

    # Add additional mint packages here
fi

### Packages for Trusty (14.04) ###
###################################
if [ $(lsb_release -rs) = '14.04' ]; then
    # Auto-accept the MS Core Fonts EULA
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

    echo "* Customizing Trusty packages"
    # Add Pepper Flash Player support for Chromium
    # Note that this temporarily downloads Chrome, and the plugin uses plugin APIs not provided in Firefox
    apt install -y pepperflashplugin-nonfree && update-pepperflashplugin-nonfree --install
    add-apt-repository -y "deb http://archive.canonical.com/ $(lsb_release -sc) partner"
    apt update -y
    apt install -y adobe-flashplugin
    apt install -y fonts-mgopen

	# Kubuntu 14.04 Specific Packages
	if [ $(dpkg-query -W -f='${Status}' kubuntu-desktop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
	    echo "* Customizing Trusty-Kubuntu packages."
	    apt install -y software-center
	    apt install -y kdewallpapers
	    apt install -y kubuntu-restricted-extras
	    apt autoremove -y muon muon-updater muon-discover
	fi

	# Xubuntu 14.04 Specific Packages
	if [ $(dpkg-query -W -f='${Status}' xubuntu-desktop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
	    echo "* Customizing Trusty-Xubuntu packages." 
	    apt install -y xubuntu-restricted-extras
	    apt remove -y gnumeric* abiword*
        echo "* Customizing Trusty-Xubuntu settings."
            apt install -y xmlstarlet
            # Make a system-wide fix so that Audio CDs autoload correctly.
            xmlstarlet ed -L -u '/channel/property[@name="autoplay-audio-cds"]/property[@name="command"]/@value' -v '/usr/bin/vlc cdda://' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
            ### And now do it for the current user.
            xfconf-query -c thunar-volman -p /autoplay-audio-cds/command -s "/usr/bin/vlc cdda://"

            # Make a system-wide fix so that Audio CDs autoload correctly.
            xmlstarlet ed -L -u '/channel/property[@name="autoplay-video-cds"]/property[@name="command"]/@value' -v '/usr/bin/vlc dvd://' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
            ### And now do it for the current user.
            xfconf-query -c thunar-volman -p /autoplay-video-cds/command -s "/usr/bin/vlc dvd://"

            # Make a system-wide fix so that Mac eject key (X86Eject) is mapped to eject (eject -r) function.
            xmlstarlet ed -L -s '/channel/property[@name="commands"]/property[@name="default"]' -t elem -n propertyTMP -v "" \
                -i //propertyTMP -t attr -n "name" -v "X86Eject" \
                -i //propertyTMP -t attr -n "type" -v "string" \
                -i //propertyTMP -t attr -n "value" -v "eject" \
                -r //propertyTMP -v property \
            /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
            ### And now do it for the current user.
            xfconf-query -c xfce4-keyboard-shortcuts -p /commands/default/XF86Eject -n -t string -s "eject"
	fi
fi

###############################
### Packages for All Releases #
###############################
# firmware-b43-installer is firmware for Broadcom wireless cards and TV capture cards
# everything that ends in -es is for spanish language support
# vlc is normally installed with mint automatically, but we've had issues where sometimes it's not installed if
# there's no network connectivity during the install process. We've included it below to solve the issue.
log_pretty "Installing common packages for all releases"
apt install -y \
	libreoffice \
	vlc \
	ubuntu-restricted-extras \
	libdvdcss2 \
	gimp \
	gparted \
	gsmartcontrol \
	krita \
	inkscape \
	chromium-browser \
	language-pack-es \
	language-pack-gnome-es \
	firmware-b43-installer \
	b43-fwcutter \
# Install cheese if the device has a webcam
if [ -c /dev/video0 ]; then # check if video0 is a character device (if it exists, it is)
	log_pretty "Webcam detected, installing cheese"
	apt install -y cheese
fi

###################################
# Check for Apple as Manufacturer #
###################################

MANUFACTURER=`dmidecode -s system-manufacturer`
if [ "$MANUFACTURER" = "Apple Inc." ]; then
    echo "You are using an $MANUFACTURER."

    # Remove current apple_ubuntu.sh
    if [ -f /usr/local/bin/apple_ubuntu.sh ]; then
    	echo "## Removing old apple_ubuntu.sh, OK."
    	rm /usr/local/bin/apple_ubuntu.sh
    fi

    # Pull fresh install.sh from github, store in /usr/local/bin
    echo "## Pulling fresh apple_ubuntu.sh, OK."
    wget -qO /usr/local/bin/apple_ubuntu.sh https://raw.githubusercontent.com/freegeekchicago/fgc-installscript/master/apple_ubuntu.sh

    # Run install.sh for updates
    echo "## Running apple_ubuntu.sh, BYE!"
    . /usr/local/bin/apple_ubuntu.sh
fi
#####################
# Reduce swappiness #
#####################

echo "#Decrease swap usage to a more reasonable level\nvm.swappiness=10" >> /etc/sysctl.conf

#############
# Finish up #
#############
log_pretty "Running apt update/upgrade again"
apt update -y && apt full-upgrade -y

log_pretty "Cleaning up"
apt autoclean -y
apt autoremove -y

######################
# Install and Run sl #
######################
# Ensure installation completed without errors

apt install -y sl
log_pretty "Installation complete -- relax, and watch this STEAM LOCOMOTIVE"; sleep 2
/usr/games/sl

##################
# Ask for reboot #
##################

if ask "Do you want to reboot now?" N; then
    echo "Rebooting now."
    reboot
else
    exit 0
fi
