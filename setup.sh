#!/bin/bash
# set -x
###################################################################################################
# Script Name:  setup.sh
# By:  Zack Thompson / Created:  1/12/2020
# Version:  1.2.0 / Updated:  2/21/2023 / By:  ZT
#
# Description:  This script sets up a new macOS environment with the provided configurations.  It 
#	would be used in scenarios where a new Mac is setup and personalized configurations are desired.
#
# 	Inspired by a multitude of other projects around the web.
#
###################################################################################################

##################################################
# Definable variables

trap "exit 1" TERM
export TOP_PID=$$

console_user=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
time_stamp=$( /bin/date +%Y-%m-%d_%H-%M-%S )

##################################################
# Helper Functions

console_writer() {

	local message="${1}"
	local message_type="${2}"
	local special="${3}"

	if [[ "${message_type}" == "Debug" ]]; then	
		if [[ "${debugging}" == "true" ]]; then
			message="[Debug] ${message}"
		else
			return
		fi
	fi

	if [[ "${special}" == "-e" ]]; then
		echo -e "${message}"
	elif [[ "${special}" == "-n" ]]; then
		echo -n "${message}"
	else
		echo "${message}"
	fi

}

defaults_helper() {
	# This is a defaults helper function to interact with the different preference domains

	local action="${1}"
	local location="${2}"
	local pref_domain="${3}"
	local key="${4}"
	local value_type="${5}"
	local value="${6}"

	local cmd=()
	cmd+=( /usr/bin/defaults )

	case "${location}" in
		"ByHost" )
			cmd+=( -currentHost )
			preference="${pref_domain}"			
		;;
		"Library" )
			cmd=( /usr/bin/sudo "${cmd[@]}" )
			preference="/Library/Preferences/${pref_domain}"
		;;
		"user" )
			if [[ "${pref_domain}" == "NSGlobalDomain" ]]; then
				preference="NSGlobalDomain"
			else
				preference="${HOME}/Library/Preferences/${pref_domain}"
			fi
		;;
		"system" )
			cmd=( /usr/bin/sudo "${cmd[@]}" )
			preference="${pref_domain}"
		;;
	esac

	case "${action}" in
		"read" )
			cmd+=( read "${preference}" "${key}" )
		;;
		"write" )
			cmd+=( write "${preference}" "${key}" "${value_type}" "${value}" )
		;;
		"delete" )
			cmd+=( delete "${preference}" "${key}" )
		;;
	esac

	console_writer "The command:  ${cmd[*]} " "Debug" >&2
	# shellcheck disable=SC2005,SC2068
	echo "$( ${cmd[@]} 2> /dev/null )"

}

ensure_file_exists() {

	local file="${1}"
	local file_verbose_msg="${2}"
	local verbose_msg_special="${4}"

	# echo "Here:  ${file}"

	if [[ -e "${file}" ]]; then
		echo "${file}"
	else
		console_writer "${file_verbose_msg}" "" "${verbose_msg_special}" >&2
		kill -s TERM $TOP_PID
	fi

}

execute_cmd() {

	local command="${1}"

	if [[ "${debugging}" != "true" ]]; then
		eval " ${command}"
	else
		console_writer "Command to execute:  \`${command}\`" "Debug"
	fi

}

exit_check() {
	# Helper function for handling process exit codes

	if [[ $1 != 0 ]]; then
		console_writer "  * Failed ${2}"
		console_writer "Exit Code:  ${3}"
		exit "${3}"
	fi

}

get_serial_number() {
	# Get the Serial Number

	/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 | 
		/usr/bin/awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}'

}

github_release_api() {
	# Helper Function to download from the GitHub API

	repo="${1}"
	downloadFile="${2}"
	desiredDownload="${3}"

	assets=$( curl --silent --header "Accept: application/vnd.github.v3+json" --url "https://api.github.com/repos/${repo}/releases/latest" 2>&1 | awk -F 'browser_download_url": "' '{print $2}' | sed 's/"//g' | sed  '/^$/d' )

	# Check if there is more than one returned
	if [[ $( echo "${assets}" | wc -l ) == "1" ]]; then
		# /usr/bin/curl --silent --show-error --no-buffer --dump-header - --speed-time 30 --location --url "${pkg}" --fail --output "${downloadFile}" > /dev/null 2>&1
		/usr/bin/curl --silent --location --url "${assets}" --output "${downloadFile}" > /dev/null 2>&1
	else
		for download in $assets ; do
			if [[ "${download}" == *"${desiredDownload}"* ]]; then
				/usr/bin/curl --silent --location --url "${download}" --output "${downloadFile}" > /dev/null 2>&1
			fi
		done
	fi

}

make_directory() {

	local directory="${1}"

	if [[ ! -d "${directory}" ]]; then
		/bin/mkdir -p "${directory}"
	fi

}

report_file_exists() {

	local file="${1}"
	local msg="${2}"
	local verbose_msg_special="${3}"

	if [[ -e "${file}" ]]; then
		console_writer "\xE2\x9C\x85 ${msg}" "" "${verbose_msg_special}"
	else
		console_writer "\xE2\x9D\x8C  ${msg}" "" "${verbose_msg_special}"
	fi

}

##################################################
# Supporting Functions

display_help() {
	# Function to display help text

	console_writer "
usage:  setup.sh [ --<action> --<type> <file> [ --pre_fix <value> | --backup-dir </path/to/file> ] ] | [ --debug | --help ]

Info:	This script sets up a new macOS environment with the provided configurations.  It would be 
	used in scenarios where a new Mac is setup and personalized configurations are desired.

Actions:
	--verify | -v	Verify the specified type(s) are configured as desired
			Example:  setup.sh --verify <type> <file> [...]

	--restore | -r	Restore the specified type(s)
			Example:  setup.sh --restore <type> <file> [...]

	--backup | -b	Backup the config type
			Example:  setup.sh --backup <type> <file> [...]

Types:
	--apps		Applications Installs:  stored in a csv
	--brew		Apps and packages obtained via Brew:  stored in a BrewFile
	--app-configs	Application configurations, stored in a csv
	--mac-configs	macOS Configurations
	--prefs		Application and macOS Preferences:  stored in a csv

Options:
	--prefix | -p	Prefix for for event names for Jamf Pro Apps
			Example:  setup.sh --apps <file> --prefix <value>

	--backup-dir	Location to backup files too
			Example:  setup.sh --app-configs <file> --backup-dir </path/to/dir>

	--debug | -d	Prints debug messages (?and doesn't make any changes)
			Example:  setup.sh [ --options ] [ --debug | -d ]

	--help | -h	Print this help dialog
			Example:  setup.sh [ --help | -h ]
"

}

arg_parse() {
	# Command Line Argument Parser
	# Pass an array to this function for proper function

	if [ $# == "0" ]; then
		console_writer "Show Help" "Debug"
		display_help
		exit 0
	fi

	# Check if optional switches were specified
	if printf '%s\n' "${parameters[@]}" | grep --extended-regexp --line-regexp --quiet "\-h|--help" ; then
		display_help
		exit 0
	fi

	if printf '%s\n' "${parameters[@]}" | grep --extended-regexp --line-regexp --quiet "\-d|--debug" ; then
		debugging="true"
	fi

	if printf '%s\n' "${parameters[@]}" | grep --extended-regexp --line-regexp --quiet "\--app-configs" ; then
		if ! printf '%s\n' "${parameters[@]}" | grep --extended-regexp --line-regexp --quiet "\--backup-dir" ; then
			console_writer "The --backup-dir argument must be used with the --app-configs option"
			exit 2
		fi
	fi

	console_writer "Options:  ${parameters[*]}" "Debug"

	while (( "$#" )); do
		console_writer "Current option:  ${1}" "Debug"

		case "${1}" in
			--verify | -v )
				action="verify"
			;;
			--restore | -r )
				action="restore"
			;;
			--backup | -b )
				action="backup"
			;;
			--apps )
				jamf_pro_apps=$( ensure_file_exists "${2}" "A file for Jamf Pro Apps was not passed" )
				shift
			;;
			--brew )
				brew_bundle=$( ensure_file_exists "${2}" "A Brewfile was not passed" )
				shift
			;;
			--app-configs )
				app_configs_file=$( ensure_file_exists "${2}" "An App Config file was not passed" )
				shift
			;;
			--mac-configs )
				mac_configs_file="true"
			;;
			--prefs )
				preference_file=$( ensure_file_exists "${2}" "A preferences file was not passed" )
				shift
			;;
			--prefix | -p )
				prefix="${2}"
				shift
			;;
			--backup-dir )
				echo "Backup location:  \`${2}\`"
				backup_dir=$( ensure_file_exists "${2}" "A location of the backup directory was not provided" )
				echo "Backup location:  \`${backup_dir}\`"
				shift
			;;
			--debug | -d )
				# Do nothing
			;;
			--help | -h )
				console_writer "Show help"
				display_help
				exit 0
			;;
			* )
				console_writer "Unknown Switch"
				display_help
			;;
		esac

		shift

	done

}

##################################################
# Core Functions

app_installs() {
	# Install Applications via Jamf Pro Self Service

	local action="${1}"
	local file="${2}"
	local prefix="${3}"

	console_writer "Application installs..."

	while IFS=, read -r app event; do
		app=$( echo "${app}" | /usr/bin/sed 's/"//g' | /usr/bin/sed 's/[\{\}]//g' | /usr/bin/sed 's/[.]app//g' | /usr/bin/sed 's/\*/.\*/g' | /usr/bin/xargs )

			if [[ "${app}" ]]; then

				case "${action}" in
					"verify" )
						if [[ ! $( /usr/bin/find -E /Applications -iregex ".*[/]${app}([.]app)?" -type d -prune -maxdepth 2 ) ]]; then
							console_writer "\xE2\x9D\x8C  ${app}" "" "-e"  # Missing
						else
							console_writer "\xE2\x9C\x85  ${app}" "" "-e"  # Ok
						fi
					;;
					"restore" )
						if [[ ! $( /usr/bin/find -E /Applications -iregex ".*[/]${app}[.]app" -type d -prune -maxdepth 1 ) ]]; then
							console_writer "Install ${app} via trigger:  ${prefix}${event%?}"
							execute_cmd "/usr/bin/sudo /usr/local/bin/jamf policy -event \"${prefix}${event%?}\" -forceNoRecon"
						fi

					;;
					"backup" )
						console_writer "The -backup switch is not supported for application installs."
						break
					;;
				esac

			fi

	done < <( /usr/bin/tail -n +2 "${file}" ) # Essentially, skip the header line

	if [[ "${action}" == "restore" ]]; then

		install_autopkg
		install_xcode_tools

	fi

}

brew_installs() {
	# Applications managed via Brew

	local action="${1}"
	local file="${2}"

	if [[ ! "$( /usr/bin/which brew )" ]]; then

		brew_paths=( "/usr/local/Homebrew/bin" "/opt/homebrew/bin")

		for path in "${brew_paths[@]}"; do
			if [[ -e "${path}/brew" ]]; then
				brew_path="${path}"
				break
			fi
		done

	else
		brew_path="$( /usr/bin/dirname "$( /usr/bin/which brew )" )"
	fi

	case "${action}" in
		"verify" )
			if [[ -e "${brew_path}/brew" ]]; then
				bundle_contents=$( /bin/cat "${file}" )

				# Get currently installed items
				formulae=$( "${brew_path}/brew" list -1 )
				taps=$( "${brew_path}/brew" tap )
				casks=$( "${brew_path}/brew" list --cask )
				masa=$( "${brew_path}/mas" list | /usr/bin/sed 's/[^ ]* //' | /usr/bin/awk -F ' \\(' '{print $1}' )

				# Get desired items from the Bundle BrewFile
				bundle_items=$( echo "${bundle_contents}" | /usr/bin/grep -v "^\#" | /usr/bin/grep "brew\|cask\|tap\|mas" | /usr/bin/sed 's/[^ ]* //' | /usr/bin/awk -F ',' '{print $1}' | /usr/bin/sed 's/"//g' )

				while IFS=$'\n' read bundle_item; do
					if [[ ! $( /usr/bin/printf '%s\n' "${formulae}" "${taps}" "${casks}" "${masa}" | /usr/bin/grep "${bundle_item}" ) ]]; then
						console_writer "\xE2\x9D\x8C  ${bundle_item}" "" "-e"  # Missing
					else
						console_writer "\xE2\x9C\x85  ${bundle_item}" "" "-e"  # Ok
					fi
				done < <( /usr/bin/printf '%s\n' "${bundle_items}")
			else
				console_writer "\xE2\x9D\x8C  Homebrew not installed" "" "-e"
			fi
		;;
		"restore" )
			# Install Homebrew, "The Missing Package Manager for macOS", if it's not installed ( https://brew.sh/ )

			# Xcode CLI Tools are a prerequisite for Homebrew
			install_xcode_tools

			if [[ ! -e "${brew_path}/brew" ]]; then
				NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
			fi

			# Update recipes
			execute_cmd "${brew_path}/brew update"

			# Install desired packages using Bundle ( https://github.com/Homebrew/homebrew-bundle )
			# execute_cmd "${brew_path} tap homebrew/bundle"
			execute_cmd "${brew_path}/brew bundle install --file ${file}"

			# Install Mac App Store command line interface ( https://github.com/mas-cli/mas )
			# execute_cmd "${brew_path} install mas"

			# Remove the quarantine attribute to get plugins working
			execute_cmd "xattr -d -r com.apple.quarantine ~/Library/QuickLook"
		;;
		"backup" )
			console_writer "The -backup switch is not supported at this time for brew installs."
			console_writer "Support may be added at a later time."
			execute_cmd "${brew_path}/brew bundle dump"
			# break
		;;
	esac

}

app_config() {
	# Application configurations and resource files

	local action="${1}"
	local file="${2}"
	local backup_dir="${3}"

	console_writer "Reading preference file:  ${file}"

	serial_number=$( get_serial_number )
	restore_from_dir="${backup_dir}"
	backup_dir="${backup_dir}/SystemSync/Configs_${serial_number}"

	if [[ -d "${backup_dir}" ]]; then
		previous_backup_time_stamp=$( /bin/cat "${backup_dir}/backup_created.txt" )
		/bin/mv "${backup_dir}" "${backup_dir}_${previous_backup_time_stamp}"
	fi

	make_directory "${backup_dir}"
	echo "${time_stamp}" > "${backup_dir}/backup_created.txt"

	# Read in the file and assign to variables
	while IFS=, read -r status application location configuration_file notes; do

		current_config=$( eval echo "\"${location}\"/${configuration_file}" )
		backup_config="${backup_dir}/${application}/${configuration_file}"
		restore_config="${restore_from_dir}/${application}/${configuration_file}"
		console_writer "Local Config:  ${current_config}" "Debug"
		console_writer "Backup To:  ${backup_config}" "Debug"

		case "${action}" in
			"verify" )
				report_file_exists "${current_config}" "Config Exists for:  ${application}" "-e"
				report_file_exists "${backup_config}" "Backup exists for:  ${application}" "-e"
			;;
			"restore" )
				# Verify the desired config exists before doing anything
				if [[ $status == "enabled" && -e "${restore_config}" ]]; then

					# Check if the local config is a already exists and back it up if so, just in case
					if [[ -e "${current_config}" ]]; then
						execute_cmd "/usr/bin/sudo /bin/mv \"${current_config}\" \"${current_config}.backup\""
					fi

					# Copy the backed up config to the proper location
					/usr/bin/sudo /usr/bin/ditto "${restore_config}" "${current_config}"

				fi
			;;
			"backup" )
				# Check if the local config exists and back it up if so
				if [[ -e "${current_config}" ]]; then
					console_writer "Backing up ${application}:  " "" "-n" 
					/usr/bin/sudo /usr/bin/ditto "${current_config}" "${backup_config}"
					console_writer "\xE2\x9C\x85" "" "-e"
				else
					console_writer "\xE2\x9D\x8C  Unable to find the local configuration for:  ${application}" "" "-e"
				fi
			;;
		esac

	done < <( /usr/bin/tail -n +2 "${file}" ) # Essentially, skip the header line
}

install_autopkg() {
	# Install AutoPkg

	console_writer "Checking for AutoPkg..."

	if [[ $( command -v autopkg ) != "0" && ! -x "/usr/local/bin/autopkg" || ! -d "/Library/AutoPkg" ]]; then
		console_writer "  * Downloading AutoPkg..."

		github_release_api "autopkg/autopkg" "/tmp/autopkg.pkg"

		# Function
		exit_check $? "downloading autopkg" 1

		console_writer "  * Installing autopkg..."
		sudo /usr/sbin/installer -dumplog -verbose -pkg "/tmp/autopkg.pkg" -allowUntrusted -target / > /dev/null 2>&1

		# Function
		exit_check $? "installing autopkg" 2

		rm "/tmp/autopkg.pkg"

	fi

	console_writer "  * Installed autopkg version:  $( autopkg version )"

}

install_xcode_tools() {
	# Install Xcode Command Line Tools

	console_writer "Checking for Xcode Command Line Tools..."

	if [[ $( /usr/bin/xcode-select -p > /dev/null 2>&1; echo $? ) != "0" ]]; then

		console_writer "  * Installing Xcode Command Line Tools..."

		# Install command line tools
		/usr/bin/sudo /usr/bin/xcode-select --install

	fi

}

macOS_config() {
	# Configure macOS configurations

	local action="${1}"
	# local backup_dir="${2}"
	# local system_sync_keychain="${backup_dir}/SystemSync/Keychains/WiFiNetworks.keychain-db"

	case "${1}" in
		"verify" )
			console_writer "The --verify switch is not supported at this time for mac_configs."
			console_writer "Support may be added at a later time."
			# console_writer "WARNING:  Minimal support for the verify switch on macOS configurations"
			# console_writer "Verifying configurations are setup..."

			# ##################################################
			# # Keychain Management

			# # Check Keychain search list
			# if [[ $( /usr/bin/security list-keychains ) != *"${system_sync_keychain}"* ]]; then
			# 	console_writer "\xE2\x9D\x8C  KeyChain Set" "" "-e"  # False
			# fi

			# if [[ $( /usr/bin/security default-keychain ) != *"${system_sync_keychain}"* ]]; then
			# 	console_writer "\xE2\x9D\x8C  KeyChain Set as Default" "" "-e"  # False
			# fi

			# if [[ $( /usr/bin/security login-keychain ) != *"${system_sync_keychain}"* ]]; then
			# 	console_writer "\xE2\x9D\x8C  KeyChain Set as Login" "" "-e"  # False
			# fi

			# console_writer "Verifications:  COMPLETE"
		;;
		"restore" )
			console_writer "Performing additional configurations..."

			##################################################
			# Remote Management / Apple Remote Desktop

			# Clear ARD Settings
			console_writer "Clearing ARD Settings..."
			/usr/bin/sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -uninstall -settings -prefs -configure -privs -none -computerinfo -set1 -1 "" -computerinfo -set2 -2 "" -computerinfo -set3 -3 "" -computerinfo -set4 -4 "" -clientopts -setreqperm -reqperm no -clientopts -setvnclegacy -vnclegacy no -restart -agent

			# Configure ARD Settings
			console_writer "Configuring ARD Settings..."
			/usr/bin/sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -privs -all -users "${console_user}" -allowAccessFor -specifiedUsers -restart -agent

			##################################################
			# Energy Saver

			# AC Adapter
			/usr/bin/sudo /usr/bin/pmset -c displaysleep 20 # Display Sleep Timer
			/usr/bin/sudo /usr/bin/pmset -c womp 1 # Wake On LAN
			/usr/bin/sudo /usr/bin/pmset -c disksleep 10 # Disk Sleep Timer
			/usr/bin/sudo /usr/bin/pmset -c sleep 0 # System Sleep Timer
			/usr/bin/sudo /usr/bin/pmset -c powernap 0 # DarkWakeBackgroundTasks (Power Nap)

			# Battery
			/usr/bin/sudo /usr/bin/pmset -b displaysleep 10 # Display Sleep Timer
			/usr/bin/sudo /usr/bin/pmset -b disksleep 10 # Disk Sleep Timer
			/usr/bin/sudo /usr/bin/pmset -b sleep 15 # System Sleep Timer
			/usr/bin/sudo /usr/bin/pmset -b powernap 0 # DarkWakeBackgroundTasks (Power Nap)
			/usr/bin/sudo /usr/bin/pmset -b lessbright 1 # ReduceBrightness

			##################################################
			# Disable File Sharing

			shares=$( /usr/bin/sudo /usr/sbin/sharing -l | /usr/bin/awk -F '^name:' '{print $2}' | /usr/bin/sed  '/^$/d' )

			while IFS=$'\n' read share; do
				/usr/bin/sudo /usr/sbin/sharing -r "${share}"
			done < <( /usr/bin/printf '%s\n' "${shares}")

			os_major_minor_version=$( /usr/bin/sw_vers -productVersion | /usr/bin/awk -F '.' '{print $1"."$2}' )

			# Check if the LaunchDaemon is running
			# Determine proper launchctl syntax based on OS Version
			# macOS 10.11+ or newer
			if [[ $( /usr/bin/bc <<< "${os_major_minor_version} >= 10.11" ) -eq 1 ]]; then

				exit_code1=$( /usr/bin/sudo /bin/launchctl print system/com.apple.smbd > /dev/null 2>&1; echo $? )

				if [[ $exit_code1 == 0 ]]; then
					/usr/bin/sudo /bin/launchctl bootout system/com.apple.smbd
				fi

			# macOS 10.10 or older
			elif [[ $( /usr/bin/bc <<< "${os_major_minor_version} <= 10.10" ) -eq 1 ]]; then

				exit_code1=$( /usr/bin/sudo /bin/launchctl list com.apple.smbd > /dev/null 2>&1; echo $? )

				if [[ $exit_code1 == 0 ]]; then
					/usr/bin/sudo /bin/launchctl unload "/System/Library/LaunchDaemons/com.apple.smbd.plist"
				fi

			fi

			##################################################
			# Misc

			# Set default browser
			/usr/bin/sudo "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --make-default-browser

			# Disable Guest User
			/usr/bin/sudo /usr/bin/dscl . -delete /Users/Guest
			/usr/bin/sudo /usr/bin/security delete-generic-password -a Guest -s com.apple.loginwindow.guest-account -D "application password" /Library/Keychains/System.keychain

			# ##################################################
			# # Keychain Management

			# login_keychain=$( /usr/bin/security login-keychain | /usr/bin/xargs )
			# if [[ "${login_keychain}" != *"${system_sync_keychain}"* ]]; then
				
			# 	# 
			# 	/usr/bin/sudo /bin/mv "${login_keychain}" "${login_keychain}.backup"

			# 	# Remove the original login.keychain
			# 	/usr/bin/security delete-keychain "${login_keychain}"

			# 	# 
			# 	/bin/ln -sf "${system_sync_keychain}" "${login_keychain}"

			# 	# Add desired Keychain to the search list
			# 	if [[ $( /usr/bin/security list-keychains ) != *"${system_sync_keychain}"* ]]; then
			# 		/usr/bin/security list-keychains -s $( /usr/bin/security list-keychains | /usr/bin/xargs ) "${login_keychain}" # "${system_sync_keychain}"
			# 	fi

			# 	# Make desired Keychain the login keychain
			# 	/usr/bin/security login-keychain -d user -s "${system_sync_keychain}"

			# fi

			# # Make desired Keychain default
			# /usr/bin/security default-keychain -d user -s "${system_sync_keychain}"

			console_writer "Configurations:  COMPLETE"
		;;
		"-backup" )
			# console_writer "Performing backup of configurations..."
			console_writer "The --backup switch is not supported at this time for mac_configs."
			console_writer "Support may be added at a later time."
			# ##################################################
			# # Keychain Management

			# all_system_wifi_networks=$( /usr/bin/sudo /usr/bin/security dump-keychain -r $( /usr/bin/security list-keychains -d system | /usr/bin/xargs ) | /usr/bin/grep '"acct"<blob>=' | /usr/bin/awk -F '"acct"<blob>=' '{print $2}' | /usr/bin/sed 's/"//g' )
			# all_user_wifi_networks=$( /usr/bin/sudo /usr/bin/security dump-keychain -r $( /usr/bin/security login-keychain | /usr/bin/xargs ) | /usr/bin/grep '"svce"<blob>=' | /usr/bin/awk -F '"svce"<blob>=' '{print $2}' | /usr/bin/sed 's/"//g' )

			# while IFS=$'\n' read WiFiSSID; do

			# 	if [[ $( /usr/bin/printf '%s\n' "${all_user_wifi_networks}" | /usr/bin/grep "${WiFiSSID}" ) ]]; then
			# 		console_writer "The network '${WiFiSSID}' already exits; update it?  [y|n]:  " "" "-n" 
			# 		read updateAnswer < /dev/tty

			# 		if [[ "${updateAnswer}" =~ [Yy]([Ee][Ss])? ]]; then
			# 			console_writer "Updating"
			# 			password=$( /usr/bin/sudo /usr/bin/security find-generic-password -a "${WiFiSSID}" -s "AirPort" -w 2> /dev/null )
			# 			/usr/bin/sudo /usr/bin/security add-generic-password -U -a "AirPort" -D "AirPort network password" -s "${WiFiSSID}" -w "${password}" -T "/usr/libexec/airportd" # -T "/Applications/Utilities/Terminal.app" # -T "AirPort"
			# 			unset password
			# 		fi

			# 	else
			# 		console_writer "Backing up SSID:  '${WiFiSSID}'"
			# 		password=$( /usr/bin/sudo /usr/bin/security find-generic-password -a "${WiFiSSID}" -s "AirPort" -w 2> /dev/null )
			# 		/usr/bin/sudo /usr/bin/security add-generic-password -U -a "AirPort" -D "AirPort network password" -s "${WiFiSSID}" -w "${password}" -T "/usr/libexec/airportd" # -T "/Applications/Utilities/Terminal.app" # -T "AirPort"
			# 		unset password
			# 	fi

			# done < <( /usr/bin/printf '%s\n' "${all_system_wifi_networks}" )

			# if [[ $( /usr/bin/security default-keychain ) != *"${system_sync_keychain}"* ]]; then
			# 	console_writer "\xE2\x9D\x8C  KeyChain Set as Default" "" "-e"  # False
			# fi
		;;
	esac

}

prefs_parser() {
	# Read in each preference configuration

	local action="${1}"
	local file="${2}"






	console_writer "Reading preference file:  ${file}"

	# Read in the file and assign to variables
	while IFS=, read status category pref_type location preference_domain key value_type value notes; do

		if [[ -z $preference_domain ]]; then
			continue
		fi

		# if [[ $status == "enabled" ]]; then

			case "${action}" in
				"verify" )
					current_value=$( defaults_helper "read" "${location}" "${preference_domain}" "${key}" )
					# Get the Exit Code
					exit_code=$?
					# console_writer "Exit Code:  ${exit_code}" "Debug"

					if [[ "${value_type}" == "bool" ]]; then
						case "${current_value}" in
							"0" )
								current_value="FALSE"
							;;
							"1" )
								current_value="TRUE"
							;;
						esac
					fi

					console_writer "System Value:  ${current_value}" "Debug"
					console_writer "Saved Value:  ${value}" "Debug"

					if [[ $exit_code != 0 ]]; then
						# echo -e "${key}:  \xE2\x9D\x93" # Not Set
						console_writer "\xF0\x9F\xA4\xB7\xE2\x80\x8D\xE2\x99\x82\xEF\xB8\x8F  ${key}" "" "-e"  # Not Set
					elif [[ "${current_value}" != "${value}" ]]; then
						console_writer "\xE2\x9D\x8C  ${key}" "" "-e"  # Failed
					else
						console_writer "\xE2\x9C\x85  ${key}" "" "-e"  # Ok
					fi
				;;
				"restore" )
					if [[ $status == "enabled" ]]; then
						defaults_helper "write" "${location}" "${preference_domain}" "${key}" "-${value_type}" "${value}"

						# Get the Exit Code
						exit_code=$?

						if [[ $exit_code == 0 ]]; then
							console_writer "\xE2\x9C\x85  ${key}" "" "-e"  # Ok
						else
							console_writer "\xE2\x9D\x8C  ${key}" "" "-e"  # Failed
						fi
					fi
				;;
				"backup" )
					console_writer "The -backup switch is not supported for preferences."
					break
				;;
			esac

		# fi

	done < <( /usr/bin/tail -n +2 "${file}" ) # Essentially, skip the header line
}


##################################################
# Bits Staged

console_writer "*****  System Sync process:  START  *****"

# Assign arguments for safe keeping
parameters=( "$@" )

arg_parse "${parameters[@]}"

##################################################

# Ask for the administrator password upfront
/usr/bin/sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do /usr/bin/sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [[ -n "${jamf_pro_apps}" ]]; then
	app_installs "${action}" "${jamf_pro_apps}" "${prefix}"
fi

if [[ -n "${brew_bundle}" ]]; then
	brew_installs "${action}" "${brew_bundle}"
fi

if [[ -n "${app_configs_file}" ]]; then
	app_config "${action}" "${app_configs_file}" "${backup_dir}"
fi

if [[ -n "${mac_configs_file}" ]]; then
	macOS_config "${action}" #"${backup_dir}"
fi

if [[ -n "${preference_file}" ]]; then
	prefs_parser "${action}" "${preference_file}"
fi

if [[ "${action}" == "restore" ]]; then
	console_writer "A reboot is recommended, would you like to perform one now?  " "" "-n"
	read -r reboot_answer < /dev/tty

	if [[ "${reboot_answer}" =~ [Yy]([Ee][Ss])? ]]; then
		console_writer "Rebooting..."
		/usr/bin/sudo /sbin/reboot
	fi
fi

console_writer "*****  System Sync process:  COMPLETE  *****"
exit 0