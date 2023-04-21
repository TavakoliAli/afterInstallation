#!/bin/bash
#Author: Ali Tavakoli

#Check either script is run as root or no
if [ $EUID -ne 0 ]; then
	echo "Run this script as root"
	exit
fi

debugFlag=false
redirect=">> /dev/null"
if [[ $1 == "-d" ]]; then
	debugFlag=true
	redirect=""
fi

echo "This script is tended to install necessary programs."
echo "Before continue make sure your internet connection is reliable."

doAuto=false

line_ () {
echo "**********************************************************************"
}

#Function to get permission from user
#The first parameter is message and
#second value is default value (y for yes and n for no)
get_allow () {

	echo ""
	line_

#Complate message in according to either default value is given or no
	if [ $# -eq 2 ]; then
		if [ $2 = "y" -o $2 = "Y" ]; then
			sel='[Y/n]'
			res_buf=0
		elif [ $2 = "n" -o $2 = "N" ]; then
			sel='[y/N]'
			res_buf=1
		fi
	else
		sel='[y/n]'
	fi


if  $doAuto ; then
	echo "$1 [Y/n]?"
	return 0
else
	read -s -n 1 -p "$1? $sel" res
	echo ""
fi

	while [ 0 ]
	do
		case $res in
			"y" | "Y")
				return 0
			;;
			"n" | "N")
				return 1
			;;
			"")
				if [ $# -eq 1 ]; then
					read -s -n 1 res
				else
					return $res_buf
				fi
			;;
			*)
				read -s -n 1 res
			;;
		esac
	done
}

#This function executes a command and prints the message
#	according to the result of the command.
#If the first parameter be 0 the command will be executed
#The second parameter is command which will be executed
#The third parameter is baner message that will be printed
#	before command executaion.
#The fourth parameter is the message that will be printed
#	if the command is executed successfully.
#The 5th parameter is message which will be print if
# the command execution fails.

print_res () {

	if [ $1 -eq 1 ]; then
		return 1
	fi

	if [ $# -eq 3 ]; then
		echo "$3 ..."
	elif [ $# -eq 5 ]; then
		echo "$3"
	fi

	if $debugFlag ; then
		echo "$2"
		eval "$2"

	else
		cmdd="$2 >> /dev/null"
		echo -e $cmdd
		eval "$cmdd"
	fi

	if [ $? -eq 0 ]; then
		
		if [ $# -eq 3 ]; then
			echo "$3 successfully."
		else
			echo "$4"
		fi

		return 0
	else

		if [ $# -eq 3 ]; then
			echo "Can not $3 !!!"
		else
			echo "$5"
		fi

		get_allow "Do you want to continue"
		if [ $? -ne 0 ]; then
			exit
		fi
		return 1
	fi
}


get_allow "Do all stuff automatically" y
if [ $? -eq 0 ]; then
	doAuto=true
fi

get_allow "Do enable additional repositories" y
if [ $? -eq 0 ]; then

	for repo in main universe restricted multiverse
	do
		
		print_res 0 "sudo apt-add-repository -y $repo" \
					"Enable $repo repository"
	done
fi

get_allow "Do update the repositories" y
print_res $? "sudo apt-get update" \
			"Update repositories"


get_allow "Do install All Essential Media Codecs" y
print_res $? "sudo apt install -y ubuntu-restricted-extras" \
			"Install All Essential Media Codecs"

get_allow "Do install GNOME Tweaks" y
print_res $? "sudo apt install -y gnome-tweaks" \
			 "Install gnome-tweaks"

get_allow "Do install GNOME Extension Manager" y
print_res $? "sudo apt install -y gnome-shell-extension-manager" \
			  "Install GNOME Extension Manager" 

#Adopted from https://fostips.com/ubuntu-21-10-two-firefox-remove-snap/
get_allow "Do install Firefox as DEB package" y
print_res $? "sudo snap remove --purge firefox"  "Remove snap based Firefox"
print_res $? "sudo apt remove --autoremove -y firefox" "Empty Firefox Deb"
print_res $? "sudo add-apt-repository -y ppa:mozillateam/ppa" "Add muzilla's repository "
print_res $? "sudo printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501\nPackage: firefox*\nPin: release o=Ubuntu\nPin-Priority: -1' | sudo tee /etc/apt/preferences.d/99mozillateamppa" "Set PPA priority"
print_res $? "sudo apt install -yt 'o=LP-PPA-mozillateam' firefox" "Install .DEB based firefox"


#Adopted from https://tutorialforlinux.com/2022/03/29/step-by-step-install-32-bit-libraries-to-run-package-on-ubuntu-22-04-64-bit/2/
# and https://forum.microchip.com/s/topic/a5C3l000000Mf3REAS/t387868?comment=P-2710047
get_allow "Do enable 32-bit Arch and install 32-bit libraries" y
if [ $? -eq 0 ]; then
	print_res 0 "sudo dpkg --add-architecture i386" "Enable 32-bit Arch"
	print_res 0 "sudo apt install -y libc6:i386 libstdc++6:i386 libncurses5:i386 zlib1g:i386" \
				"Install libraries"
fi

get_allow "Do you want to install necessary libraries" y
if [ $? -eq 0 ]; then

#adopted from https://fosspost.org/things-to-do-after-installing-ubuntu/
	print_res 0 "sudo apt-get install -y libfuse2 libfuse-dev" \
				"Install libfuse2(Need to rum AppImage)"
				
#adopted from https://github.com/platformio/platformio-core-installer/issues/1774
	print_res 0 "sudo apt-get install -y python3-venv" \
				"Install python3-venv(need for platformIO)"
fi

debug_buf=$debugFlag
debugFlag=true
get_allow "Do you want to install callibre" y
print_res $? "sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin" \
			  "Install callibre"
debugFlag=$debug_buf


pathXc8Compiler () {
	echo "Start pathing compiler ..."
	if [[ -e $1/bin/xclm.old ]]; then
		echo "The compiler was pathed previously"
		return 0
	elif [[ ! -e $1/bin/xclm ]] ; then
		echo "Can not find necessary file\(xclm\)"
		return 1
	else

		returnPath=$(pwd)
		if [[ -d "$1/pic/bin" ]]; then
			#for version > 2
			eval "sudo cp -v $1/bin/xclm $1/pic/bin/xclm.old $redirect"
			eval "sudo cp -v ./xc8Compilers/Fix/Linux/xclm $1/pic/bin/ $redirect"
			cd "$1/pic/bin"
			eval "sudo ./xclm $redirect"
		else
			#for version < 2
			eval "sudo mv -v $1/bin/xclm $1/bin/xclm.old $redirect"
			eval "sudo cp -v ./xc8Compilers/Fix/Linux/xclm $1/bin $redirect"
			cd "$1/bin"
			eval "sudo ./xclm $redirect"
		fi

		if [[ $? -eq 0 ]]; then
			if [[ -d "$1/pic/bin" ]]; then
				eval "sudo cp -vf $1/pic/bin/xclm $1/pic/bin/xclm.old $1/bin $redirect"
			fi
			cd $returnPath
			echo "Path compiler successfully"
			return 0
		else
			cd $returnPath
			echo "Can not path compiler !!!"
			return 1
		fi
	fi
}

installXc8Compiler () {

	get_allow "Do you want to install xc8 $1 compiler" y
	if [[ 1 -eq $? ]];then
		return 1
	fi

	echo "NOTE: Do not change the default installation directory"
	print_res 0 "sudo ./xc8Compilers/xc8-${1}.run --mode text $redirect  <<-EOF










y
1

y
y

EOF
"  "Install xc8 $1 compiler"

if [[ $? -eq 0 ]]; then
	pathXc8Compiler "/opt/microchip/xc8/$1"
fi
	return $?
}

installXc8Compiler v1.35
installXc8Compiler v1.36
installXc8Compiler v2.31
installXc8Compiler v2.40

get_allow "Do install MPLABX-v6.05.sh" y
print_res $? "sudo ./xc8Compilers/MPLABX-v6.05.sh" "Install MPLABX-v6.05.sh"

get_allow "Do install keepassxc" y
print_res $? "sudo sudo add-apt-repository -y ppa:phoerious/keepassxc" "Add repository"
print_res $? "sudo apt-get install -y keepassxc" "Install keepassxc"

get_allow "Do install golden dictunary" y
print_res $? "sudo apt-get install -y goldendict" "Install goldendict"

get_allow "Do install Visual Studio Code" y
print_res $? "sudo apt install -y wget gpg apt-transport-https" "Install necessary packages"
print_res $? "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && cd ." "Download gpg key"
print_res $? "sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg" "Install key"
print_res $? "sudo printf 'deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list" "Add repository"
print_res $? "rm -f packages.microsoft.gpg" "Remove temporary files"
print_res $? "sudo apt update" "Update repository"
print_res $? "sudo apt install -y code" "Install Visual Studio Code"


get_allow "Do install KiCad" y
if [ $? -eq 0 ]; then
	echo "Search for repository ..."
	kicadRepo=$(wget -qO - https://www.kicad.org/download/linux/ | grep -om 1 -e " ppa:kicad/kicad-.*-releases")
	
	if [[ -n $kicadRepo ]];then
		echo "Found repository: $kicadRepo"
	elif [[ -z $kicadRepo && $doAuto == false ]]; then
		echo "Can not find repository, see \"https://www.kicad.org/download/linux/\" and enter repository manually (it is like \"ppa:kicad/kicad-X.X-releases\") or just hit enter to cancel KiCad installation."
		read kicadRepo
	else
		echo "Can not find repository, cancel installation."
	fi

	if [[ -n $kicadRepo ]];then
		print_res 0 "sudo add-apt-repository -y $kicadRepo" "Add KiCad repository"
		print_res $? "sudo apt install -y kicad" "Install KiCad"
	fi

	unset kicadRepo
fi

gitShPath=/home/ali/Clones/git-sh
get_allow "Do install Git-sh" y
print_res $? "make -C $gitShPath" "Make project"
print_res $? "sudo make -C $gitShPath install" "Install git-sh"
print_res $? "make -C $gitShPath clean" "Clean project directory"
unset gitShPath

get_allow "Do update dev-rule (Need for usb2serial module)" y
print_res $? "curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules" "Update rules"

install_python3 () {

	print_res $1 "sudo apt-get -y install python3 python3-pip" "Install python3 and pip"
	return $?
}

get_allow "Do install python3 and pip" y
install_python3 $?

get_allow "Do install esptool.py for ESP module programming" y
if [[ 0 -eq $? ]]; then

	print_res 0 "python3 --version $redirect && pip --version" "Searching for python3 ..." "find python3" "Can not find python3"
	if [[ 0 -ne $? ]]; then

		install_python3 $?
	fi
	print_res $? "pip install esptool" "Install esptool.py"
fi
	
get_allow "Do install moserial terminal?" y
print_res $? "sudo apt-get -y install moserial" "Install moserial terminal"

#Adopted from : https://operavps.com/docs/after-installing-ubuntu/
get_allow "Do Turn on Minimize on Click" y
print_res $? "gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize'" \
			  "Enable Minimize on Click" "Fails to enable Minimize on Click"

#Adopted from : https://operavps.com/docs/after-installing-ubuntu/
get_allow "Do clean the system" n
if [ $? -eq 0 ]; then
	print_res 0 "sudo apt-get -y autoclean" \
				"Clean packages"
	print_res 0 "sudo apt-get -y autoremove" \
				"Remove unused dependencies" 
	print_res 0 "sudo apt-get -y clean" \
				"Cleanup apt-cache" 
fi

echo "Install all stuff, please restart system ..."

