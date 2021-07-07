#!/bin/bash

#GLOABLS
export WHAT_ARE_WE_CALLING_THIS="Linux Server Quality Checker"
# SCREEN NAMES
export CLAMAV_SCREEN_NAME="clam_av_scanner"
# RESULTS FILES
export CLAMAV_RESULTS_FILE="clam_av_results.txt"


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
	yes | apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install screen clamav clamav-daemon

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
	# Setup return array
	local -n RETURN_INSTALLER_FINAL=$1
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

	# Parse as array
	declare -a RETURN_INSTALLER

	# Set to final retunr array
	RETURN_INSTALLER_FINAL=$RETURN_INSTALLER
	return 0
}

# run_clamav_scan ...
run_clamav_scan() {
	# Results file exists, delete it
	if test -f "$CLAMAV_RESULTS_FILE"; then
		rm "$CLAMAV_RESULTS_FILE"
	fi

	# Create results file
	touch "$CLAMAV_RESULTS_FILE"

	# Run the scan outputting the results to the results file
	clamscan --exclude-dir=/proc/* --exclude-dir=/sys/* -i -r --bell / >> "$CLAMAV_RESULTS_FILE"
}

# check_clam_av_infected_files ....
check_clam_av_infected_files() {
	# `BEGIN{FS=":"}`                   # Use the colon as a field separator
	# `tolower($1) == "infected files"` # convert field 1 to lowercase, then look for a field called "infected files"
	# `{print $2;}`                     # print the second field
	awk 'BEGIN{FS=":"} tolower($1) == "infected files" {print $2;}' results.txt
}

# What are we running??
RUN_HELPER=0
RUN_INSTALLER=0
RUN_CLAM_AV_SCAN=0
CHECK_CLAM_AV_SCAN_RESULTS=0

# Figure out what we're running based off the flags
while test $# -gt 0; do
	case "$1" in

		# Run the helper
		"-i" | "--help")
			RUN_HELPER=1
		;;

		# Run the installer
		"-i" | "--install")
			RUN_INSTALLER=1
		;;

		# Run the clamav scanner
		"-c" | "--clamav-scan")
			RUN_CLAM_AV_SCAN=1
		;;

		# Check clamav scan results
		"-C" | "--clamav-check")
			CHECK_CLAM_AV_SCAN_RESULTS=1
		;;

		# Nothing to do?
		*)
			echo "Please add the flag of what you want to do. See --help for more options"
			exit 1
		;;

	esac
done

# WANTS TO RUN HELPER
if [[ $RUN_HELPER -gt 0 ]]; then
	echo "$WHAT_ARE_WE_CALLING_THIS [options]"
	echo " "
	echo "options:"
	echo "-h, --help                shows the options (you're on this right now)"
	echo "-i, --install             installs the required packages (screen, clamav, etc)"
	echo "-c, --clamav-scan         runs the clamav scanner"
	echo "-C, --clamav-check        checks the clamav infected file results"
	exit 0
fi

# WANTS TO RUN THE INSTALLER
if [[ $RUN_INSTALLER -gt 0 ]]; then
	# Run Installer
	local INSTALLER
	run_installer INSTALLER
	declare -a INSTALLER

	# Handle based on return
	echo "${INSTALLER[1]}"
	exit ${INSTALLER[0]}
fi

# WANTS TO RUN CLAMAV SCAN
if [[ $RUN_CLAM_AV_SCAN -gt 0 ]]; then
	# Run the scan in a screen so we can come back to it later
	# Adding `exec sh` will prevent the screen session from ending after script is done i.e) screen -dm bash -c 'sleep 5; exec sh'
	screen -S "$CLAMAV_SCREEN_NAME" -dm bash -c "./check.sh --clamav-scan"
	exit 0
fi

# WANTS TO CHECK THE CLAM AV RESULTS



