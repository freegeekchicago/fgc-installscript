#!/bin/sh

### Simple minded install script for
### FreeGeek Chicago by David Eads
### Updates by Brent Bandegar, Dee Newcum, James Slater, Alex Hanson, Benjamin Mintz

### Available on FreeGeek Chicago's github Account at http://git.io/Ool_Aw

### Import DISTRIB_CODENAME and DISTRIB_RELEASE
. /etc/lsb-release

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

# Make sure we're using Ubuntu trusty
if [ $(lsb_release -rs) != '14.04']; then
    echo "Sorry, only Ubuntu 14.04 is supported."
    exit 1
fi

# Each package should be on a separate line inside of a heredoc
# If a package is not found or broken, aptitude continues anyway.
sudo apt-get -y install aptitude

###################################
### Packages for Trusty (14.04) ###
###################################

# Add Pepper Flash Player support for Chromium
# Note that this temporarily downloads Chrome, and the plugin uses plugin APIs not provided in Firefox
echo "* Customizing Trusty packages"
apt-get -y install pepperflashplugin-nonfree &&
update-pepperflashplugin-nonfree --install

# Kubuntu 14.04 Specific Packages
if [ $(dpkg-query -W -f='${Status}' kubuntu-desktop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "* Customizing Trusty-Kubuntu packages."
    aptitude -y install <<-EOF
    software-center
    kdewallpapers
    kubuntu-restricted-extras
EOF
fi
apt-get -y autoremove muon muon-updater muon-discover

# Xubuntu 14.04 Specific Packages
if [ $(dpkg-query -W -f='${Status}' xubuntu-desktop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "* Customizing Trusty-Xubuntu packages."
    xubuntu-restricted-extras
    apt-get -y remove gnumeric* abiword*
    echo "* Customizing Trusty-Xubuntu settings."
        xmlstarlet
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

# Using aptitude and a heredoc makes the process TONS faster
aptitude -y install <<-EOF
    # Make sure an office suite is installed
    libreoffice

    # Add codecs / plugins that most people want
    ubuntu-restricted-extras
    non-free-codecs
    libdvdcss2

    # Add design / graphics programs
    gimp
    krita
    inkscape

    # Add VLC and mplayer to play all multimedia
    vlc
    mplayer
    totem-mozilla
    # Need to justify installation of mplayer and totem-mozilla

    # Misc Packages. Need to justify installation of each.
    gcj-jre
    ca-certificates
    chromium-browser
    # Also install Chrome?
    hardinfo

    # Add spanish language support
    language-pack-es
    language-pack-gnome-es

    # Install nonfree firmware for Broadcom wireless cards and TV capture cards
    linux-firmware-nonfree firmware-b43-installer b43-fwcutter

    # Install libc6:i386 to fix dependency problems for nyancat:i386
    libc6:i386
EOF
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
