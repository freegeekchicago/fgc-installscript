#!/bin/sh

### Simple minded install script for
### FreeGeek Chicago by David Eads
### Updates by Brent Bandegar, Dee Newcum, James Slater, Alex Hanson

### Available on FreeGeek` Chicago's github Account at http://git.io/Ool_Aw

### Import DISTRIB_CODENAME and DISTRIB_RELEASE
. /etc/lsb-release

### Get the integer part of $DISTRIB_RELEASE. Bash/test can't handle floating-point numbers.


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
        echo -n "$1 [$prompt] "
        read REPLY
 
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

# Make sure we're using 
if [ $(lsb_release -rs) != '14.04']; then
    echo "Sorry, only Ubuntu 14.04 is supported."
    exit 1
fi

# Each package should have it's own apt-get line.
# If a package is not found or broken, the whole apt-get line is terminated.

###################################
### Packages for Trusty (14.04) ###
###################################

# Add Pepper Flash Player support for Chromium
# Note that this temporarily downloads Chrome, and the plugin uses plugin APIs not provided in Firefox
echo "* Customizing Trusty packages"
apt-get -y install pepperflashplugin-nonfree &&
update-pepperflashplugin-nonfree --install
apt-get -y install fonts-mgopen

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
    echo "* Customizing Trusty-Xubuntu settings."
        apt-get -y install xmlstarlet
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

# Make sure an office suite is installed
apt-get -y install libreoffice

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
apt-get -y install linux-firmware-nonfree firmware-b43-installer b43-fwcutter

# Install libc6:i386 to fix dependency problems for nyancat:i386
apt-get -y install libc6:i386

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

#################################
# Install and Run nyancat #
#################################
# Ensure installation completed without errors

# Install the latest nyancat from the utopic (14.10) mirror
URL='http://archive.ubuntu.com/ubuntu/pool/universe/n/nyancat/nyancat_1.4.4-1_i386.deb'; FILE=`mktemp`; wget "$URL" -qO $FILE && sudo dpkg -i $FILE; rm $FILE
if [ -e "/usr/bin/nyancat" ]; then
	echo "Installation complete -- relax, and watch this NYAN CAT"; sleep 2
    # -n: no counter, -s: no titlebar text, -f: run for 34 frames (~3 seconds)
	nyancat -nsf 34
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
