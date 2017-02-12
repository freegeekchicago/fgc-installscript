# FreeGeek Chicago Install Script

This repository provides the files
FreeGeek Chicago uses
to make changes to the base installation of
our Xubuntu or Ubuntu installations.
The two files available in this repository do the following:

<!--
	Use <i> instead of <em> or <strong> because 
	these are technical names. They will still be italicized.
	Ideally we'd use <dfn> but GitHub-flavored Markdown
	doesn't support it.
-->
- <i>install.txt</i> is a short script
that pulls down the current install.sh from github.
It resides on FreeGeek Chicago's webserver
at http://freegeekchicago.org/files/install.txt
- <i>install.sh</i> is the script that does the heavy lifting.
install.txt places install.sh in the /usr/local/bin folder.
- <i>iMac_installer.sh</i> is for iMacs only.
It customizes Linux Mint installs for them.
- <i>apple_ubuntu.sh</i> fixes apple laptops
running any Ubuntu derivative.

© 2012-2016 FreeGeekChicago, NFP
X11-Licensed (see LICENSE.txt)
