#!/bin/bash

# get_OS ...  Returns a predictable string value of the operating system name
get_OS() {
	# Setup return array
	local -n RETURN_OS=$1
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

	RETURN_OS=("$OS" "$OSFull")
}

# installer_alpine ...
installer_alpine() {
	# Setup return array
	local -n RETURN_ALPINE=$1
	#RETURN_ALPINE=(0 "SUCCESS!")
	#RETURN_ALPINE=(1 "FAIL!")
	#return 1
}

# installer_arch ...
installer_arch() {
	# Setup return array
	local -n RETURN_ARCH=$1
	#RETURN_ARCH=(0 "SUCCESS!")
	#RETURN_ARCH=(1 "FAIL!")
	#return 1
}

# installer_debian ...
installer_debian() {
	# Setup return array
	local -n RETURN_DEBIAN=$1

	# Install clamav
	export DEBIAN_FRONTEND=noninteractive
	yes | apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install clamav clamav-daemon

	# Install failes
	if [ $? -gt 0 ]; then
		RETURN_DEBIAN=(1 "Failed Installing Clamav")
		return 1
	fi

	#RETURN_DEBIAN=(1 "FAIL!")
	RETURN_DEBIAN=(0 "Successfully Installed Packages")
	return 0
}

# installer_gentoo ...
installer_gentoo() {
	# Setup return array
	local -n RETURN_GENTOO=$1
	#RETURN_GENTOO=(0 "SUCCESS!")
	#RETURN_GENTOO=(1 "FAIL!")
	#return 1
}

# installer_red_hat ...
installer_red_hat() {
	# Setup return array
	local -n RETURN_RED_HAT=$1
	#RETURN_RED_HAT=(0 "SUCCESS!")
	#RETURN_RED_HAT=(1 "FAIL!")
	#return 1

	# install on centos
	#sudo yum -y install epel-release
	#sudo yum clean all
	#sudo yum install clamav
}


# run_installer ... figures out which installer to run based on the OS and runs it
run_installer() {
	# To get array returns
	local RETURN_OPERATING_SYSTEM
	local RETURN_INSTALLER

	# GET OS
	get_OS RETURN_OPERATING_SYSTEM
	declare -a RETURN_OPERATING_SYSTEM

	# Output some info
	echo "Operating System Constant: ${RETURN_OPERATING_SYSTEM[0]}"
	echo "Operating System Full: ${RETURN_OPERATING_SYSTEM[1]}"

	# Run the correct installer
	echo "Installing Required Packages"
	case ${RETURN_OPERATING_SYSTEM[0]} in

		# ALPINE - apk
		"ALPINE")
			installer_alpine RETURN_INSTALLER
		;;

		# ARCH - pacman
		"ARCH")
			installer_arch RETURN_INSTALLER
		;;

		# DEBIAN DISTROS - apt
		"DEBIAN" | "UBUNTU")
			installer_debian RETURN_INSTALLER
		;;

		# GENTOO - portage
		"GENTOO")
			installer_gentoo RETURN_INSTALLER
		;;

		# RED HAT DISTROS - yum
		"ALMA" | "CENTOS" | "FEDORA" | "ROCKY")
			installer_red_hat RETURN_INSTALLER
		;;

		*)
			RETURN_INSTALLER=(1, "Unknown Operating System")
		;;

	esac

	# Parse as array and handle
	declare -a RETURN_INSTALLER
	echo ${RETURN_INSTALLER[1]}
	exit ${RETURN_INSTALLER[0]}
}

# run_clamav_scan ...
run_clamav_scan() {
	touch results.txt
	clamscan --exclude-dir=/proc/* --exclude-dir=/sys/* -i -r --bell / >> results.txt
}

# Install clamav
run_installer

# Run scanner
#clamscan --exclude-dir=/proc/* --exclude-dir=/sys/* -i -r --bell /

# updates virus database
#sudo freshclam # DONT NEED BECAUSE IT RUNS A SERVICE THAT AUTO UPDTES IT

# rings a bell
#clamscan -r --bell -i / #this goes CRAYZEEE if you dontr exlude /proc and /sys


# https://www.transip.co.uk/knowledgebase/entry/1899-installing-and-configuring-clamav-debian-and/
