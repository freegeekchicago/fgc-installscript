#!/bin/bash

## Define Variables
MODEL=`dmidecode -s system-product-name`
MACBOOK21='MacBook2,1'
MACBOOK41='MacBook4,1'
#~/.config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml

## Install webcam firmware
webcam() {
    apt-get -y install cheese
    apt-get -y install isight-firmware-tools
    wget -qO /lib/firmware/AppleUSBVideoSupport http://fgc-nfs/iSight/AppleUSBVideoSupport
    ift-extract -a /lib/firmware/AppleUSBVideoSupport
}

### Install Broadcom Wireless Driver
wireless() {
    apt-get -y install firmware-b43-installer b43-fwcutter
}

## Fix touchpad issues
touchpad() {
### Current session
    synclient FingerLow=10
    synclient FingerHigh=20
### Permanently
    if [ ! -d "/etc/X11/xorg.conf.d" ]; then
        mkdir /etc/X11/xorg.conf.d
    fi
 
    echo 'Section "InputClass"
    Identifier "touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "synaptics"
    Option "FingerLow" "10"
    Option "FingerHigh" "20"
EndSection' >> /etc/X11/xorg.conf.d/10-synaptics.conf
}

## MACBOOK2,1
if [ $MODEL = $MACBOOK21 ]; then
    echo "You are using an Apple $MODEL."
    echo "Installing iSight webcam"
    webcam
    echo "Installing wireless drivers"
    wireless
    echo "Fixing touchpad sensitivity"
    touchpad
fi

## MACBOOK4,1
if [ $MODEL = $MACBOOK41 ]; then
    echo "You are using an Apple $MODEL."
    echo "Installing iSight webcam"
    webcam
    echo "Installing wireless drivers"
    wireless
    echo "Fixing touchpad sensitivity"
    touchpad
fi

