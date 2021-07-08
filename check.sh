#!/bin/bash

#GLOABLS
WHAT_ARE_WE_CALLING_THIS="Linux Server Quality Checker"
CLAMAV_SCREEN_NAME="clam_av_scanner"
CLAMAV_RESULTS_FILE="clam_av_results.txt"

file_exists() {
	# Results file exists, delete it
	if test -f "$1"; then
		echo "true"
	else
		echo "false"
	fi
}

# get_OS ...  Returns a predictable string value of the operating system name
get_OS() {
	# Setup return array
	local -n RETURN_OS=$1

	# Get OS from hostnamectl
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
	RETURN_ARCH=(0 "SUCCESS!")
	#RETURN_ARCH=(1 "FAIL!")
	return 1
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
	# Setup return arrays
	local RETURN_OPERATING_SYSTEM
	local -n RETURN_INSTALLER=$1 # The caller will passing thier own local array here to tap in to final installer array

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

# run_check_clam_av_scan_results ....
run_check_clam_av_scan_results() {
	# Setup return array
	local -n RETURN_CLAMAV_RESULTS_CHECK=$1

	# Does a results file exist?
	RESULTS_FILE_EXISTS=$(file_exists $CLAMAV_RESULTS_FILE)

	# We do not have a results file, we cant parse anything
	if [[ $RESULTS_FILE_EXISTS == "false" ]]; then
		RETURN_CLAMAV_RESULTS_CHECK=(1 "There is no clamav scan results file. Please run the clamav scan using ./check.sh --clamav-scan")
		return 0
	fi

	# we have a file, lets see if screen is still running
	POTENTIAL_CLAMAV_SCREEN=$(screen -ls | awk 'BEGIN{FS="\t"} /'$CLAMAV_SCREEN_NAME'/ {print $2;}')

	# Screen exists meaning clamav is still running, we cant really check yet
	if [[ $POTENTIAL_CLAMAV_SCREEN == *"$CLAMAV_SCREEN_NAME"* ]]; then
		# We're gonna return 2 here because this isnt exactly a fail, just needs more time
		RETURN_CLAMAV_RESULTS_CHECK=(2 "Clamav is still running. Screen process is still available. Try again later")
		return 0
	fi

	# Get the content of the results file
	RESULTS_FILE_CONTENT=$(cat "$CLAMAV_RESULTS_FILE")
	# Strip all spaces
	RESULTS_FILE_CONTENT_NO_SPACES=${RESULTS_FILE_CONTENT//[[:space:]]/}

	# Results file is empty
	if [[ $RESULTS_FILE_CONTENT_NO_SPACES == "" ]]; then
		# We're gonna return 2 here because this isnt exactly a fail, just needs more time
		RETURN_CLAMAV_RESULTS_CHECK=(2 "Clamav is still running. Results file is empty. Try again later")
		return 0
	fi

	### -- PARSE INFECTED FILES FROM SCAN RESULTS -- ###
	# `BEGIN{FS=":"}`                   # Use the colon as a field separator
	# `tolower($1) == "infected files"` # convert field 1 to lowercase, then look for a field called "infected files"
	# `{print $2;}`                     # print the second field
	INFECTED_FILES=$(awk 'BEGIN{FS=":"} tolower($1) == "infected files" {print $2;}' "$CLAMAV_RESULTS_FILE")

	# We found infected files
	if [[ $INFECTED_FILES -gt 0 ]]; then
		RETURN_CLAMAV_RESULTS_CHECK=(1 "$INFECTED_FILES Infected Files have been found. Test Failed!")
		return 0
	fi

	# We good
	RETURN_CLAMAV_RESULTS_CHECK=(0 "No infected files have been found. Test Success!")
}

# What are we running??
RUN_HELPER=0
RUN_INSTALLER=0
RUN_CLAM_AV_SCAN=0
RUN_CLAM_AV_SCAN_IN_SCREEN=0
RUN_CHECK_CLAM_AV_SCAN_RESULTS=0

# Figure out what we're running based off the flags

case "$1" in

	# Run the helper
	"-h" | "--help")
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

	# Run the clamav scanner
	"-S" | "--clamav-scan-in-screen")
		RUN_CLAM_AV_SCAN_IN_SCREEN=1
	;;

	# Check clamav scan results
	"-C" | "--clamav-check")
		RUN_CHECK_CLAM_AV_SCAN_RESULTS=1
	;;

	# Nothing to do?
	*)
		echo "Please add the flag of what you want to do. See --help for more options"
		exit 1
	;;

esac

# main ...
main() {
	# WANTS TO RUN HELPER
	if [[ $RUN_HELPER -gt 0 ]]; then
		echo "$WHAT_ARE_WE_CALLING_THIS"
		echo " "
		echo "options:"
		echo "-h, --help                          shows the options (you're on this right now)"
		echo "-i, --install                       installs the required packages (screen, clamav, etc)"
		echo "-c, --clamav-scan                   runs the clamav scanner"
		echo "-S, --clamav-scan-in-screen         runs the clamav scanner in a screen called $CLAMAV_SCREEN_NAME"
		echo "-C, --clamav-check                  checks the clamav results file [$CLAMAV_RESULTS_FILE] for infected files"
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
		run_clamav_scan
		exit 0
	fi

	# WANTS TO RUN CLAMAV SCAN IN SCREEN
	if [[ $RUN_CLAM_AV_SCAN_IN_SCREEN -gt 0 ]]; then
		# Run the scan in a screen so we can come back to it later
		# Note: If you dont want the screen session to end when done executing, adding `exec sh` will prevent the screen session from ending after script is done i.e) screen -dm bash -c 'sleep 5; exec sh'
		screen -S "$CLAMAV_SCREEN_NAME" -dm bash -c "./check.sh --clamav-scan"
		exit 0
	fi

	# WANTS TO CHECK THE CLAM AV RESULTS
	if [[ $RUN_CHECK_CLAM_AV_SCAN_RESULTS -gt 0 ]]; then
		local CHECK_CLAM_AV_SCAN_RESULTS
		run_check_clam_av_scan_results CHECK_CLAM_AV_SCAN_RESULTS
		declare -a CHECK_CLAM_AV_SCAN_RESULTS
		# Handle based on return
		echo "${CHECK_CLAM_AV_SCAN_RESULTS[1]}"
		exit ${CHECK_CLAM_AV_SCAN_RESULTS[0]}
	fi
}

# Run main function
main