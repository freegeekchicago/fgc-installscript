#!/bin/bash

### Simple minded install script for
### FreeGeek Chicago by David Eads
### Updates by Brent Bandegar, Dee Newcum, James Slater, Alex Hanson

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

### Disable Source Repos
#
# Check to see if Source repos are set ON and turn OFF
if grep -q "deb-src#" /etc/apt/sources.list; then
    echo "* Commenting out source repositories -- we don't mirror them locally."
    sed -i 's/deb-src /#deb-src#/' /etc/apt/sources.list
else
    echo "# Already disabled source repositories"
fi

# Figure out if this part of the script has been run already
# TODO: Look at the default sources.list
#grep "${DISTRIB_CODENAME}-updates universe" /etc/apt/sources.list
#if (($? == 1)); then
#    echo "* Adding ${DISTRIB_CODENAME} updates line for universe and multiverse"
#    cp /etc/apt/sources.list /etc/apt/sources.list.backup
#    echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DISTRIB_CODENAME}-updates universe multiverse" >> /etc/apt/sources.list
#else
#    echo "# Already added universe and multiverse ${DISTRIB_CODENAME}-updates line to sources,"
#fi

# Figure out if this part of the script has been run already
if grep -q "${DISTRIB_CODENAME}-updates universe" /etc/apt/sources.list; then
    echo "# Already added universe and multiverse ${DISTRIB_CODENAME}-updates line to sources,"
else
    echo "* Adding ${DISTRIB_CODENAME} updates line for universe and multiverse"
    cp /etc/apt/sources.list /etc/apt/sources.list.backup
    echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DISTRIB_CODENAME}-updates universe multiverse" >> /etc/apt/sources.list
fi

### Enable Medibuntu Repos
#
# Commented out, no longer maintained.
#if [ -e /etc/apt/sources.list.d/medibuntu.list ]; then
#        echo "#  Already added Medibuntu repo, OK."
#else
#        wget -q http://packages.medibuntu.org/medibuntu-key.gpg -O- | apt-key add -
#        wget http://www.medibuntu.org/sources.list.d/${DISTRIB_CODENAME}.list -O /etc/apt/sources.list.d/medibuntu.list
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
if [ -e /etc/apt/sources.list.d/videolan.sources.list ]; then
    echo "# Already added libdvdcss repo, OK."
else
    echo "* Adding VideoLAN's libdvdcss repo, OK."
	echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.sources.list
#       echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.sources.list
	wget -O - http://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add - libdvdcss
fi


### Enable Wine Repo
#
# Commented out, no longer maintained. See http://www.winehq.org/download/ubuntu
#if [ -e /etc/apt/sources.list.d/winehq.list ]; then
#        echo '#  Already added Wine repo, OK.'
#else
#        wget -q http://wine.budgetdedicated.com/apt/387EE263.gpg -O- | apt-key add -
#        wget http://wine.budgetdedicated.com/apt/sources.list.d/${DISTRIB_CODENAME}.list -O /etc/apt/sources.list.d/winehq.list
#fi

### Enable Wine PPA
#
if [ -e /etc/apt/sources.list.d/ubuntu-wine-ppa-${DISTRIB_CODENAME}.list ]; then
    echo '# Already added Wine PPA, OK.'
else
    echo '* Adding Wine PPA.'
    if [ $DISTRIB_MAJOR_RELEASE -ge 11 ]; then
                add-apt-repository -y ppa:ubuntu-wine/ppa # Do this if Ubuntu 11.04 or higher
        else
                add-apt-repository ppa:ubuntu-wine/ppa # Do this if Ubuntu 10.10 or lower
    fi
fi

### Update everything
#
apt-get -y update && apt-get -y upgrade

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

# Add spanish language support
apt-get -y install language-pack-gnome-es language-pack-es 

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
echo "Installation complete -- relax, and watch this STEAM LOCOMOTIVE"
if [ $DISTRIB_MAJOR_RELEASE -ge 10 ]; then
    /usr/games/sl
else
    sl
fi

## EOF
