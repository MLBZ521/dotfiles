#!/bin/bash

###################################################################################################
# Script Name:  setup.sh
# By:  Zack Thompson / Created:  1/12/2020
# Version:  1.0.0 / Updated:  1/17/2020 / By:  ZT
#
# Description:  This script sets up a new macOS environment with the provided configurations.  It 
#	would be used in scenarios where a new Mac is setup and personalized configurations are desired.
#
# 	Inspired by a multitude of other projects around the web.
#
###################################################################################################

echo "*****  SystemSync process:  START  *****"

##################################################
# Script variables
cwd=$(/usr/bin/dirname "${0}")
consoleUser=$( /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
type=()
dropboxHome=$( /bin/ls ${HOME} | /usr/bin/grep "Dropbox" )

# Definable variables
appConfigsFile="${cwd}/appconfigs.csv"
brewBundle="${cwd}/Brewfile"
jamfProApps="${cwd}/JamfProAppsToInstall.plist"
preferenceFile="${cwd}/preferences.csv"
SyncChain="${HOME}/${dropboxHome}/SystemSync/Keychains/Sync.keychain-db"

# Ask for the administrator password upfront
/usr/bin/sudo -v

# Keep-alive: update existing `sudo` time stamp until script has finished
while true; do /usr/bin/sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

##################################################
# Setup Functions

# Function to display help text
displayHelp() {
echo "
usage:  setup.sh [ -action ] [ type ] | [ -help ]

Info:	This script sets up a new macOS environment with the provided configurations.  
		It would be used in scenarios where a new Mac is setup and personalized 
		configurations are desired.

Actions:  [ -verify | -restore | -backup ]
	-verify		Verify the specified type(s) are configured as desired
				Example:  setup.sh -verify [ type ]

	-restore	Restore the specified type(s)
				Example:  setup.sh -restore [ type ]

	-backup		Backup the config type
				Example:  setup.sh -backup [ type ]

	-help | -h 	Print this help dialog
				Example:  setup.sh [ -help | -h ]

Types:
	all		Perform action on all types
	apps		Applications Installs:  stored in a plist
	brew		Apps and packges obtained via Brew:  stored in a BrewFile
	configs		Applications and macOS Configurations:  partly stored in a csv
	prefs		Application and macOS Preferences:  stored in a csv
"
}

# Read in each preference configuration
prefsParser() {
	echo "Reading preference file:  ${2}"

	# Read in the file and assign to variables
	while IFS=, read status category pref_type location preference_domain key value_type value notes; do

		if [[ $status == "enabled" ]]; then

			case "${1}" in
				"-verify" )
					currentValue=$( defaultsHelper "read" "${location}" "${preference_domain}" "${key}" )
					# Get the Exit Code
					exitCode=$?
					# echo "Exit Code:  ${exitCode}"

					if [[ "${value_type}" == "-bool" ]]; then
						case "${currentValue}" in
							"0" )
								currentValue="FALSE"
							;;
							"1" )
								currentValue="TRUE"
							;;
						esac
					fi

					# echo "CurrentValue:  ${currentValue}"
					# echo "value:  ${value}"

					if [[ $exitCode != 0 ]]; then
						# echo -e "${key}:  \xE2\x9D\x93" # Not Set
						echo -e "${key}:  \xF0\x9F\xA4\xB7\xE2\x80\x8D\xE2\x99\x82\xEF\xB8\x8F" # Not Set
					elif [[ "${currentValue}" != "${value}" ]]; then
						echo -e "${key}:  \xE2\x9D\x8C" # Failed
					else
						echo -e "${key}:  \xE2\x9C\x85" # Ok
					fi
				;;
				"-restore" )
					defaultsHelper "write" "${location}" "${preference_domain}" "${key}" "${value_type}" "${value}"

					# Get the Exit Code
					exitCode=$?

					if [[ $exitCode != 0 ]]; then
						echo -e "${key}:  \xE2\x9D\x8C" # Failed
					else
						echo -e "${key}:  \xE2\x9C\x85" # Ok
					fi
				;;
				"-backup" )
					echo "The -backup switch is not supported for preferences."
					break
				;;
			esac

		fi

	done < <( /usr/bin/tail -n +2 "${2}" ) # Essentially, skip the header line.
}

# This is a defaults helper function to interact with the different preference domains
defaultsHelper() {
	cmd=()
	cmd+=( /usr/bin/defaults )

	case "${2}" in
		"ByHost" )
			cmd+=( -currentHost )
			preference="${3}"			
		;;
		"Library" )
			cmd=( /usr/bin/sudo "${cmd[@]}" )
			preference="/Library/Preferences/${3}"
		;;
		"user" )
			if [[ "${preference_domain}" == "NSGlobalDomain" ]]; then
				preference="NSGlobalDomain"
			else
				preference="${HOME}/Library/Preferences/${3}"
			fi
		;;
		"system" )
			cmd=( /usr/bin/sudo "${cmd[@]}" )
			preference="${3}"
		;;
	esac

	case "${1}" in
		"read" )
			cmd+=( read "${preference}" "${4}" )
		;;
		"write" )
			cmd+=( write "${preference}" "${4}" "${5}" "${6}" )
		;;
		"delete" )
			cmd+=( delete "${preference}" "${4}" )
		;;
	esac

	"${cmd[@]}" 2> /dev/null
	# echo "The command:  ${cmd[@]} "
	# exit
}

# Install Applications via Jamf Pro Self Service
appInstalls() {
echo "Application installs..."

	while IFS='=' read app event; do
		app=$( echo "${app}" | /usr/bin/sed 's/"//g' | /usr/bin/sed 's/[\{\}]//g' | /usr/bin/sed 's/[.]app//g' | /usr/bin/sed 's/\*/.\*/g' | /usr/bin/xargs )

			if [[ "${app}" ]]; then

				case "${1}" in
					"-verify" )
						if [[ ! $( /usr/bin/find -E /Applications -iregex ".*[/]${app}[.]app" -type d -prune -maxdepth 1 ) ]]; then
							echo -e "${app}:  \xE2\x9D\x8C"  # Missing
						else
							echo -e "${app}:  \xE2\x9C\x85"  # Ok
						fi
					;;
					"-restore" )
						if [[ ! $( /usr/bin/find -E /Applications -iregex ".*[/]${app}[.]app" -type d -prune -maxdepth 1 ) ]]; then
							echo "Install ${app} via trigger:  ${event%?}"
							/usr/bin/sudo /usr/local/bin/jamf policy -event "${event%?}"
						fi
					;;
					"-backup" )
						echo "The -backup switch is not supported for application installs."
						break
					;;
				esac
			fi

	done < <( /usr/bin/defaults "read" "${2}" )  # Essentially, skip the header line.
}

# Applications managed via Brew
brewInstalls() {

	case "${1}" in
		"-verify" )
			if [[ $( /usr/bin/which brew ) ]]; then
				bundleContents=$( /bin/cat "${2}" )

				# Get currently installed items
				formulae=$( /usr/local/bin/brew list -1 )
				taps=$( /usr/local/bin/brew tap )
				casks=$( /usr/local/bin/brew cask list )
				masa=$( /usr/local/bin/mas list | /usr/bin/sed 's/[^ ]* //' | /usr/bin/awk -F ' \\(' '{print $1}' )

				# Get desired items from the Bundle BrewFile
				bundleItems=$( echo "${bundleContents}" | /usr/bin/grep -v "^\#" | /usr/bin/grep "brew\|cask\|tap\|mas" | /usr/bin/sed 's/[^ ]* //' | /usr/bin/awk -F ',' '{print $1}' | /usr/bin/sed 's/"//g' )

				while IFS=$'\n' read bundleItem; do
					if [[ ! $( /usr/bin/printf '%s\n' "${formulae}" "${taps}" "${casks}" "${masa}" | /usr/bin/grep "${bundleItem}" ) ]]; then
						echo -e "${bundleItem}:  \xE2\x9D\x8C" # Missing
					else
						echo -e "${bundleItem}:  \xE2\x9C\x85" # Ok
					fi
				done < <( /usr/bin/printf '%s\n' "${bundleItems}")
			else
				echo -e "Brew:  \xE2\x9D\x8C" # Missing
			fi
		;;
		"-restore" )
			# Install Homebrew, "The Missing Package Manager for macOS", if it's not installed ( https://brew.sh/ )
			if [[ ! $( /usr/bin/which brew ) ]]; then
				/usr/bin/ruby -e "$( /usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install )"
			fi

			# Update recipes
		 	/usr/local/bin/brew update

			# Install Mac App Store command line interface ( https://github.com/mas-cli/mas )
		 	/usr/local/bin/brew install mas

			# Sign in to the Apple Store so apps can install be installed
		 	/usr/local/bin/mas signin --dialog mas@example.com

			# Install desired packages using Bundle ( https://github.com/Homebrew/homebrew-bundle )
		 	/usr/local/bin/brew tap homebrew/bundle
		 	/usr/local/bin/brew bundle

	 		# Remove the quarantine attribute to get plugins working
		 	xattr -d -r com.apple.quarantine ~/Library/QuickLook
		;;
		"-backup" )
			echo "The -backup switch is not supported at this time for brew installs."
			echo "Support may be added at a later time."
			break
		;;
	esac
}

# Restore application configurations and resource files
appConfigs() {
	echo "Reading preference file:  ${2}"

	# Read in the file and assign to variables
	while IFS=, read status application location configuration_file notes; do

		if [[ $status == "enabled" ]]; then
			localConfig=$( eval echo "\"${location}\"/${configuration_file}" )
			syncConfig="${HOME}/"${dropboxHome}"/SystemSync/Configs/${application}/${configuration_file}"
			# echo "Local:  ${localConfig}" 
			# echo "Sync:  ${syncConfig}"

			# Check if localConfig is a Symbolic link
			if [[ ! -h "${localConfig}" ]]; then

				case "${1}" in
					"-verify" )
						echo -e "${application} Symlink:  \xE2\x9D\x8C"
					;;
					"-restore" )
						# Verify the desired config exists before doing anything
						if [[ -e "${syncConfig}" ]]; then

							# Check if the local config is a already exists and back it up if so, just in case
							if [[ -e "${localConfig}" && ! -h "${localConfig}" ]]; then
								/usr/bin/sudo /bin/mv "${localConfig}" "${localConfig}.backup"
							fi

							# Symlink the desired config to the proper location
							/usr/bin/sudo /bin/ln -sf "${syncConfig}" "${localConfig}"

						fi
					;;
					"-backup" )
						# Check if there is already a desired configuration before doing anything, if so, back it up
						if [[ -e "${syncConfig}" ]]; then
							/bin/mv "${syncConfig}" "${syncConfig}.backup"
						fi

						# Check if the local config exists and back it up if so
						if [[ -e "${localConfig}" ]]; then
							echo -n "Backing up ${application}:  "
							/usr/bin/sudo /usr/bin/ditto "${localConfig}" "${syncConfig}"
							echo "COMPLETE"
						else
							echo "Unable to find the local configuration for:  ${application}"
						fi
					;;
				esac
			fi
		fi

	done < <( /usr/bin/tail -n +2 "${2}" ) # Essentially, skip the header line.
}

# Configure macOS configurations
macOSconfigs() {

	case "${1}" in
		"-verify" )
			echo "WARNING:  Minimal support for the verify switch on macOS configurations"
			echo "Verifying configurations are setup..."

			##################################################
			# Keychain Management

			# Check Keychain search list
			if [[ $( /usr/bin/security list-keychains ) != *"${SyncChain}"* ]]; then
				echo -e "KeyChain Set:  \xE2\x9D\x8C" # False
			fi

			if [[ $( /usr/bin/security default-keychain ) != *"${SyncChain}"* ]]; then
				echo -e "KeyChain Set as Default:  \xE2\x9D\x8C" # False
			fi

			if [[ $( /usr/bin/security login-keychain ) != *"${SyncChain}"* ]]; then
				echo -e "KeyChain Set as Login:  \xE2\x9D\x8C" # False
			fi

			echo "Verifications:  COMPLETE"
		;;
		"-restore" )
			echo "Performing additional configurations..."

			# ##################################################
			# # Remote Management / Apple Remote Desktop

			# # Clear ARD Settings
			# Echo "Clearing ARD Settings..."
			# /usr/bin/sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -uninstall -settings -prefs -configure -privs -none -computerinfo -set1 -1 "" -computerinfo -set2 -2 "" -computerinfo -set3 -3 "" -computerinfo -set4 -4 "" -clientopts -setreqperm -reqperm no -clientopts -setvnclegacy -vnclegacy no -restart -agent

			# # Configure ARD Settings
			# Echo "Configuring ARD Settings..."
			# /usr/bin/sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -privs -all -users "${consoleUser}" -allowAccessFor -specifiedUsers -restart -agent

			# ##################################################
			# # Energy Saver

			# # AC Adapter
			# /usr/bin/sudo /usr/bin/pmset -c displaysleep 20 # Display Sleep Timer
			# /usr/bin/sudo /usr/bin/pmset -c womp 1 # Wake On LAN
			# /usr/bin/sudo /usr/bin/pmset -c disksleep 10 # Disk Sleep Timer
			# /usr/bin/sudo /usr/bin/pmset -c sleep 0 # System Sleep Timer
			# /usr/bin/sudo /usr/bin/pmset -c powernap 0 # DarkWakeBackgroundTasks (Power Nap)

			# # Battery
			# /usr/bin/sudo /usr/bin/pmset -b displaysleep 10 # Display Sleep Timer
			# /usr/bin/sudo /usr/bin/pmset -b disksleep 10 # Disk Sleep Timer
			# /usr/bin/sudo /usr/bin/pmset -b sleep 15 # System Sleep Timer
			# /usr/bin/sudo /usr/bin/pmset -b powernap 0 # DarkWakeBackgroundTasks (Power Nap)
			# /usr/bin/sudo /usr/bin/pmset -b lessbright 1 # ReduceBrightness

			# ##################################################
			# # Disable File Sharing
			# shares=$( /usr/bin/sudo /usr/sbin/sharing -l | /usr/bin/awk -F '^name:' '{print $2}' | /usr/bin/sed  '/^$/d' )

			# while IFS=$'\n' read share; do
			# 	/usr/bin/sudo /usr/sbin/sharing -r "${share}"
			# done < <( /usr/bin/printf '%s\n' "${shares}")

			# # Check if the LaunchDaemon is running.
			# # Determine proper launchctl syntax based on OS Version.
			# if [[ $osVersion -ge 11 ]]; then
			# 	exitCode1=$( /usr/bin/sudo /bin/launchctl print system/com.apple.smbd > /dev/null 2>&1; echo $? )

			# 	if [[ $exitCode1 == 0 ]]; then
			# 		/usr/bin/sudo /bin/launchctl bootout system/com.apple.smbd
			# 	fi

			# elif [[ $osVersion -le 10 ]]; then
			# 	exitCode1=$( /usr/bin/sudo /bin/launchctl list com.apple.smbd > /dev/null 2>&1; echo $? )

			# 	if [[ $exitCode1 == 0 ]]; then
			# 		/usr/bin/sudo /bin/launchctl unload "/System/Library/LaunchDaemons/com.apple.smbd.plist"
			# 	fi

			# fi

			# ##################################################
			# # Misc

			# # Set default browser
			# /usr/bin/sudo /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --make-default-browser

			# # Disable Guest User
			# # /usr/bin/sudo /usr/bin/dscl . -delete /Users/Guest
			# # /usr/bin/sudo /usr/bin/security delete-generic-password -a Guest -s com.apple.loginwindow.guest-account -D "application password" /Library/Keychains/System.keychain

			# # Install command line tools -- Handled via Brew
			# # /usr/bin/sudo /usr/bin/xcode-select --install

			# ##################################################
			# # Keychain Management

			loginKeychain=$( /usr/bin/security login-keychain | /usr/bin/xargs )
			# if [[ "${loginKeychain}" != *"${SyncChain}"* ]]; then
				
				# 
				/usr/bin/sudo /bin/mv "${loginKeychain}" "${loginKeychain}.backup"

				# Remove the original login.keychain
				/usr/bin/security delete-keychain "${loginKeychain}"

				# 
				/bin/ln -sf "${SyncChain}" "${loginKeychain}"

				# Add desired Keychain to the search list
				# if [[ $( /usr/bin/security list-keychains ) != *"${SyncChain}"* ]]; then
			 	/usr/bin/security list-keychains -s $( /usr/bin/security list-keychains | /usr/bin/xargs ) "${loginKeychain}" # "${SyncChain}"
				# fi

				# # Make desired Keychain the login keychain
				# /usr/bin/security login-keychain -d user -s "${SyncChain}"

			# fi

			# Make desired Keychain default
			/usr/bin/security default-keychain -d user -s "${SyncChain}"

			echo "Configurations:  COMPLETE"
		;;
		"-backup" )
			echo "Performing backup of configurations..."

			##################################################
			# Keychain Management

			allSystemWiFiNetworks=$( /usr/bin/sudo /usr/bin/security dump-keychain -r $( /usr/bin/security list-keychains -d system | /usr/bin/xargs ) | /usr/bin/grep '"acct"<blob>=' | /usr/bin/awk -F '"acct"<blob>=' '{print $2}' | /usr/bin/sed 's/"//g' )
			allUserWiFiNetworks=$( /usr/bin/sudo /usr/bin/security dump-keychain -r $( /usr/bin/security login-keychain | /usr/bin/xargs ) | /usr/bin/grep '"svce"<blob>=' | /usr/bin/awk -F '"svce"<blob>=' '{print $2}' | /usr/bin/sed 's/"//g' )

			while IFS=$'\n' read WiFiSSID; do

				if [[ $( /usr/bin/printf '%s\n' "${allUserWiFiNetworks}" | /usr/bin/grep "${WiFiSSID}" ) ]]; then
					echo -n "The network '${WiFiSSID}' already exits; update it?  [y|n]:  "
					read updateAnswer < /dev/tty

					if [[ "${updateAnswer}" == "Yes" || "${updateAnswer}" == "yes" || "${updateAnswer}" == "y" ]]; then
						echo "Updating"
						password=$( /usr/bin/sudo /usr/bin/security find-generic-password -a "${WiFiSSID}" -s "AirPort" -w 2> /dev/null )
					 	/usr/bin/sudo /usr/bin/security add-generic-password -U -a "AirPort" -D "AirPort network password" -s "${WiFiSSID}" -w "${password}" -T "/usr/libexec/airportd" # -T "/Applications/Utilities/Terminal.app" # -T "AirPort"
						unset password
					fi

				else
					echo "Backing up SSID:  '${WiFiSSID}'"
					password=$( /usr/bin/sudo /usr/bin/security find-generic-password -a "${WiFiSSID}" -s "AirPort" -w 2> /dev/null )
					/usr/bin/sudo /usr/bin/security add-generic-password -U -a "AirPort" -D "AirPort network password" -s "${WiFiSSID}" -w "${password}" -T "/usr/libexec/airportd" # -T "/Applications/Utilities/Terminal.app" # -T "AirPort"
					unset password
				fi

			done < <( /usr/bin/printf '%s\n' "${allSystemWiFiNetworks}" )

			if [[ $( /usr/bin/security default-keychain ) != *"${SyncChain}"* ]]; then
				echo -e "KeyChain Set as Default:  \xE2\x9D\x8C" # False
			fi
		;;
	esac
}

##################################################
# Bits Staged

if [ $# == "0" ]; then
	echo "Show Help"
	displayHelp
	exit 1
fi

while (( "$#" )); do
	# echo "Switches:  $#"
	# echo "current:  ${1}"

	case "${1}" in
		-verify | -restore | -backup )
			action="${1}"
		;;
		all )
			appInstalls "${action}" "${jamfProApps}"
			brewInstalls "${action}" "${brewBundle}"
			appConfigs "${action}" "${appConfigsFile}"
			macOSconfigs "${action}"
			prefsParser "${action}" "${preferenceFile}"
			break
		;;
		apps )
			appInstalls "${action}" "${jamfProApps}"
		;;
		brew )
			brewInstalls "${action}" "${brewBundle}"
		;;
		configs )
			appConfigs "${action}" "${appConfigsFile}"
			# macOSconfigs "${action}"
		;;
		prefs )
			prefsParser "${action}" "${preferenceFile}"
		;;
		-h | -help )
			echo "Show help"
			displayHelp
			exit 0
		;;
		* )
			echo "Unknown Switch"
			displayHelp
		;;
	esac

	shift
done

if [[ "${action}" == "-restore" ]]; then
	echo -n "A reboot is recommended, would you like to perform one now?  "
	read rebootAnswer < /dev/tty

	if [[ "${rebootAnswer}" == "Yes" || "${rebootAnswer}" == "yes" || "${rebootAnswer}" == "y" ]]; then
		echo "Rebooting..."
		/usr/bin/sudo /sbin/reboot
	fi
fi

echo "*****  SystemSync process:  COMPLETE  *****"
exit 0