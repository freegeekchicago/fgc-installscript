#!/bin/bash
## Basic script to fix, setup, and prettify Linux Mint on iMacs for Freegeek Chicago
## By Grant Garrett-Grossman

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

function pause(){
   read -p "$*"
}

echo "################################################"
echo "#  FreeGeek Chicago iMac Linux Mint Installer  #"
echo "################################################"
echo
echo
echo "Welcome to the wonderful installer script to setup Linux Mint on iMacs!"
echo "Let's get ready to rumble!"
echo

# Check if root
if [[ $EUID -ne 0 ]]; then
	echo "You must be a root user" 2>&1
	exit 1
fi

# Get current user
user=$(who am i | awk '{print $1}')

###########Package Management#######################	
# Treat recommended packages as dependencies
echo "Designating all recommended packages as dependencies ..."
sed -i 's/false/true/g' /etc/apt/apt.conf.d/00recommends
sed -i 's/false/true/g' /etc/apt/apt.conf.d/99synaptic
echo "Done!"
echo

# Make all updates visible
echo "Making sure all updates are visible ..."
sed -i -r 's/level1_visible = False/level1_visible = True/' "/home/$user/.config/linuxmint/mintUpdate.conf"
sed -i -r 's/level2_visible = False/level1_visible = True/' "/home/$user/.config/linuxmint/mintUpdate.conf"
sed -i -r 's/level3_visible = False/level1_visible = True/' "/home/$user/.config/linuxmint/mintUpdate.conf"
sed -i -r 's/level4_visible = False/level1_visible = True/' "/home/$user/.config/linuxmint/mintUpdate.conf"
sed -i -r 's/level5_visible = False/level1_visible = True/' "/home/$user/.config/linuxmint/mintUpdate.conf"
echo "Done!"
echo

# Make all security updates visible and safe
echo "Making sure all security updates are automatically selected ..."
sed -i -r 's/security_visible = False/security_visible = True/' "/home/$user/.config/linuxmint/mintUpdate.conf"
sed -i -r 's/security_safe = False/security_safe = True/' "/home/$user/.config/linuxmint/mintUpdate.conf"
echo "Done!"
echo
	
# Add ppa
echo "Adding Numix ppa ..." 
apt-add-repository -y ppa:numix/ppa # for icons
echo "Done!"
echo

# Update
echo "Updating and upgrading ..."
echo
apt-get update
apt-get -y upgrade
echo
echo "Done!"
echo	

#########################################################

# Enable firewall
echo "Starting and enabling firewall ..." 
ufw enable
echo "Done!"
echo
	
# Make swappiness reasonable
swappiness=$( cat /proc/sys/vm/swappiness) # gets current swappiness
if [ $swappiness -gt 10]
then
	echo "Reducing swappiness to 10 ..."
	echo "# Set swap usage to a more reasonable level" >> /etc/sysctl.conf
	echo "vm.swappiness=10" >> /etc/sysctl.conf
	echo "Done!"
	echo
fi
else
	echo "Swap usage was already set to 10"
	echo "Was this script already run?"	
	echo
	
# Disable the flawed hibernate (suspend-to-disk)
echo "Disabling suspend to disk ..."
mv -v /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla /
echo "Done!"
echo

#############Install stuff###############
echo "Installing a bunch of stuff ..."
echo "Please sit back and relax, the train will be there soon."
echo
# Codecs and important stuff
apt-get -y install ubuntu-restricted-extras
apt-get -y install flashplugin-installer # necessary?
apt-get -y install libdvdcss2

# Add spanish language support
apt-get -y install language-pack-es	
apt-get -y install language-pack-gnome-es
	
# Install nonfree firmware for Broadcom wireless cards and TV capture cards
apt-get -y install linux-firmware-nonfree firmware-b43-installer b43-fwcutter
	
# Games!!!!!
apt-get -y install aisleriot gnome-cards-data gnomine quadrapassel gnome-sudoku
	
# Activate mumlock
apt-get -y install numlockx

# Install a better looking icon set (aka: numix)
sudo apt-get install numix-icon-theme numix-icon-theme-circle

# Install and fix docky (bluetooth icon bug)
apt-get -y docky
killall docky
cp /usr/share/applications/cinnamon-settings.desktop /usr/share/applications/cinnamon-settings.desktop.`date +"%m_%d_%Y"`
sed '/Keywords=/a\StartupWMClass=Cinnamon-settings.py' -i /usr/share/applications/cinnamon-settings.desktop
rm ~/.cache/docky/docky.desktop.*.cache

# Other stuff
apt-get -y install inkscape
apt-get -y install gcj-jre
apt-get -y install ca-certificates
apt-get -y install chromium-browser
apt-get -y install hardinfo
apt-get -y install cheese

echo "Done!"
echo
##############################################

# Ensure installation completed without errors
apt-get -y install sl
echo "Installation complete -- relax, and watch this STEAM LOCOMOTIVE"; sleep 2
/usr/games/sl
	
#TODO do these automatically
echo "###################################################################"
echo "# 	   Please do the following:       			  #"
echo "###################################################################" 
echo "	1) Install Proprietary drivers if available from the driver manager"
echo "	2) Selected the Numix icons from the theme manager"
echo "	3) Downloaded the Mountain lion theme and selected it for Window borders via the theme manager"
echo "	4) Downloaded the Void theme and selected it for Desktop via the theme manager"
echo " 	5) Started Docky amd configured it to: start on login, have a removable drive addon, make it look nice, and include everyday programs (Thunderbird, Firefox/Chromium, LibreOffice, File Manager, Terminal" 
echo "	6) Moved panel to top and removed the Window List Applet and launchers"
echo "	7) Upgraded the kernel to the the latest via the Update Manager"
echo " 	8) Downloaded, enabled and configured the desktop cube extension"
echo "	9) Change the effects: make windows fly down when minimized, move when closed, fly up when maximised"
echo 

echo "Did you finish all of that?"
pause 'If so please press [Enter]'
echo
echo "Great!"
echo "Please contribute on Github if you are tired of doing all of that stuff manually"
echo
echo "Bye!"
echo
echo "Just kidding :)"
echo

if ask "Do you want to reboot now?" Y; then
	echo "Rebooting now."
	reboot
else
	exit 0
fi

## EOF
