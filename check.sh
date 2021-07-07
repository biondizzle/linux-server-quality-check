#!/bin/bash

# get_OS ...  Returns a predictable string value of the operating system name
get_OS() {
	OSFull=$(hostnamectl | grep "Operating System")
	OS="UNKNOWN"

	if [[ $OSFull == *"Alma"* ]]; then
		OS="ALMA"
	fi

	if [[ $OSFull == *"Alpine"* ]]; then
		OS="ALPINE"
	fi

	if [[ $OSFull == *"Arch"* ]]; then
		OS="ARCH"
	fi

	if [[ $OSFull == *"Centos"* ]]; then
		OS="CENTOS"
	fi

	if [[ $OSFull == *"Debian"* ]]; then
		OS="DEBIAN"
	fi

	if [[ $OSFull == *"Fedora"* ]]; then
		OS="FEDORA"
	fi

	if [[ $OSFull == *"Gentoo"* ]]; then
		OS="GENTOO"
	fi

	if [[ $OSFull == *"Rocky"* ]]; then
		OS="ROCKY"
	fi

	if [[ $OSFull == *"Ubuntu"* ]]; then
		OS="UBUNTU"
	fi

	echo $OS
}

# installer_alpine ...
installer_alpine() {
	echo "ALPINE"
}

# installer_arch ...
installer_arch() {
	echo "ARCH"
}

# installer_debian ...
installer_debian() {
	echo "DEBIAN"
	#sudo apt install clamav
	#apt install -y clamav-daemon
	#sudo reboot
}

# installer_gentoo ...
installer_gentoo() {
	echo "GENTOO"
}

# installer_red_hat ...
installer_red_hat() {
	echo "RED HAT"
	# install on centos
	#sudo yum -y install epel-release
	#sudo yum clean all
	#sudo yum install clamav
}


# run_installer ... figures out which installer to run based on the OS and runs it
run_installer() {
	# store the OS name
	OS=get_OS

	case $OS in

		# ALPINE - apk
		"ALPINE")
			installer_alpine
		;;

		# ARCH - apk
		"ARCH")
			installer_arch
		;;

		# DEBIAN DISTROS - apk
		"DEBIAN" | "UBUNTU")
			installer_debian
		;;

		# GENTOO - apk
		"GENTOO")
			installer_gentoo
		;;

		# RED HAT DISTROS - yum
		"ALMA" | "CENTOS" | "FEDORA" | "ROCKY")
			installer_red_hat
		;;

		*)
			echo -n "Unknown Distro"
			exit 1
		;;

	esac

}

# Install clamav
run_installer

# Run scanner
clamscan --exclude-dir=/proc/* --exclude-dir=/sys/* -i -r --bell /

# updates virus database
#sudo freshclam # DONT NEED BECAUSE IT RUNS A SERVICE THAT AUTO UPDTES IT

# rings a bell
#clamscan -r --bell -i / #this goes CRAYZEEE if you dontr exlude /proc and /sys


# https://www.transip.co.uk/knowledgebase/entry/1899-installing-and-configuring-clamav-debian-and/
