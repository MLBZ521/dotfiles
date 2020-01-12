#!/bin/bash

##################################################
# Login Window
# /Library/Preferences/com.apple.loginwindow.plist

defaults write com.apple.loginwindow AdminHostInfo HostName
defaults write com.apple.loginwindow SHOWFULLNAME -bool true # Show username and password fields

# sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool false # Show language menu in the top right corner of the boot screen


##################################################
# Finder
# /Users/zthomps3/Library/Preferences/com.apple.finder.plist

defaults write NSGlobalDomain AppleShowAllExtensions -bool true # Show all file extensions
defaults write com.apple.finder AppleShowAllFiles -bool true # Show all (hidden) files
defaults write com.apple.finder ShowPathbar -bool true # Show path bar
defaults write NSGlobalDomain AppleShowScrollBars -string Always # Always show scroll bars
defaults write com.apple.finder ShowStatusBar -bool true # Show status bar
# defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2 # ?
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # Do not create .DS_Store files on Mounted Network Volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true # Do not create .DS_Store files on Mounted USB Volumes
defaults write NSGlobalDomain AppleActionOnDoubleClick Maximize # Double-click a window's title bar to "zoom"
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf" # When performing a search, search the current folder by default
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false # Disable the warning when changing a file extension
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true # Expand save panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true # Expand print panel by default

# Show icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Use column view in all Finder windows by default
# Four-letter codes for the other view modes: `Nlsv`, `icnv`, `clmv`, `glyv`
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"


##################################################
# Menu Bar

# Reset icons in the Menu Bar and set visible items
defaults write com.apple.systemuiserver menuExtras -array \
	"/System/Library/CoreServices/Menu Extras/Volume.menu" \
    "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
    "/System/Library/CoreServices/Menu Extras/AirPort.menu" \
    "/System/Library/CoreServices/Menu Extras/Battery.menu" \
    "/System/Library/CoreServices/Menu Extras/Clock.menu"

defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.remotedesktop" -bool true # Enable remote desktop icon in Menu Bar
defaults write com.apple.menuextra.battery.plist ShowPercent -string YES # Enable battery percentage in Menu Bar
defaults write com.apple.airplay showInMenuBarIfPresent -bool false # Don't show mirroring options in menu bar
defaults write com.apple.menuextra.clock DateFormat -string "EEE h:mm:ss a" # Show date on the menu bar


##################################################
# Screensaver

defaults -currentHost write com.apple.screensaver idleTime -int 600 # Start after number of seconds
defaults -currentHost write com.apple.screensaver showClock -bool true # Show with clock
defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName "Computer Name" path "/System/Library/Frameworks/ScreenSaver.framework/Resources/Computer Name.saver" type 0 # Set the desired screen saver


##################################################
# Dock

# defaults write com.apple.dock orientation bottom # Dock Position on screen
defaults write com.apple.dock autohide -bool true # Automatically hide and show the Dock
defaults write com.apple.dock autohide-delay -float 0 # Remove the auto-hiding Dock delay
defaults write com.apple.dock no-bouncing -bool false # ?
defaults write com.apple.dock launchanim -bool true # Animate opening applications
defaults write com.apple.dock tilesize -int 40 # Size of dock icon
defaults write com.apple.dock largesize -int 45 # Size of hovered dock icon (magnification)
defaults write com.apple.dock magnification -bool true # Magnification enabled
defaults write com.apple.dock mineffect genie # Minimize window effect
defaults write com.apple.dock show-process-indicators -bool true # Show indicators for open applications

# defaults write com.apple.dock show-recents -bool false # Don’t show recent applications in Dock

# Probably only want to run this on a *new* Mac 
defaults write com.apple.dock persistent-apps -array # Wipe all (default) app icons from the Dock

# Add preferred icons to the dock
defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Notes.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Google Chrome.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Code.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/Remote Deskstop.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'


##################################################
# Mission Control / Dashboard

defaults write com.apple.dock mru-spaces -bool false # Automatically rearrange Spaces based on most recent use
defaults write com.apple.dock workspaces-auto-swoosh -boolean false # When switching to an application, switch to a Space with open windows for the application
defaults write com.apple.dock expose-group-apps -bool false # Group Windows by application
defaults write com.apple.dock dashboard-in-overlay -bool true # Don’t show Dashboard as a Space
defaults write com.apple.dashboard mcx-disabled -bool true # Disable Dashboard


##################################################
# Energy Saver

# AC Adapter
pmset -c displaysleep 20 # Display Sleep Timer
pmset -c womp 1 # Wake On LAN
pmset -c disksleep 10 # Disk Sleep Timer
pmset -c sleep 0 # System Sleep Timer
pmset -c powernap 0 # DarkWakeBackgroundTasks (Power Nap)

# Battery
pmset -b displaysleep 10 # Display Sleep Timer
pmset -b disksleep 10 # Disk Sleep Timer
pmset -b sleep 15 # System Sleep Timer
pmset -b powernap 0 # DarkWakeBackgroundTasks (Power Nap)
pmset -b lessbright 1 # ReduceBrightness


##################################################
# Keyboard

defaults write NSGlobalDomain AppleKeyboardUIMode -int 3 # Allows Tab to move keyboard focus between "All Controls"
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true # Use F1, F2, etc. keys as standard function keys
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false # Disable press-and-hold for keys in favor of key repeat


##################################################
# Trackpad

defaults write com.apple.AppleMultitouchTrackpad.plist TrackpadThreeFingerTapGesture -int 0 # Trackpad > Point & Click > Look up & data detectors
defaults write com.apple.AppleMultitouchTrackpad.plist TrackpadRightClick -bool true # Trackpad > Point & Click > Tap to click
defaults write com.apple.AppleMultitouchTrackpad.plist Clicking -bool false # Trackpad > Point & Click > Secondary click
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2 # Tracking speed for the Trackpad
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false # Trackpad Scroll & Zoom:  Scroll direction: Natural (Disable scroll direction "Natural")
defaults write com.apple.AppleMultitouchTrackpad.plist TrackpadRotate -bool false # Trackpad > Scroll & Zoom > Rotate
defaults write com.apple.AppleMultitouchTrackpad.plist TrackpadTwoFingerDoubleTapGesture -bool false # Trackpad > Scroll & Zoom > Smart zoom
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false # Trackpad > More Gestures > Swipe between pages
defaults write com.apple.AppleMultitouchTrackpad.plist TrackpadThreeFingerHorizSwipeGesture -int 2 # Trackpad > Point & Click > Secondary click #  Trackpad > More Gestures > Swipe between full-screen apps
defaults write com.apple.AppleMultitouchTrackpad.plist TrackpadTwoFingerFromRightEdgeSwipeGesture -int 0 # Trackpad > Point & Click > Secondary click #  Trackpad > More Gestures > Notification Center
defaults write com.apple.dock showMissionControlGestureEnabled -bool true # Trackpad > More Gestures > Mission Control
defaults write com.apple.dock showAppExposeGestureEnabled -bool true #  Trackpad > More Gestures > App Expose
defaults write com.apple.dock showLaunchpadGestureEnabled -bool true # Trackpad > More Gestures > Launchpad
defaults write com.apple.dock showDesktopGestureEnabled -bool true # Trackpad > More Gestures > Show Desktop


##################################################
# Mouse

defaults write NSGlobalDomain com.apple.mouse.scaling -float 2 # Tracking speed for the Mouse
defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0.75 # Tracking speed for the Scrollwheel


##################################################
# Sound

defaults -currentHost write com.apple.soundpref AlertsUseMainDevice -int 0 # Play sound effect through:  0 = Internal Speakers, 1 = Selected sound output device
defaults write NSGlobalDomain com.apple.sound.uiaudio.enable -int 1 # Play user interface sound effects
defaults write NSGlobalDomain com.apple.sound.beep.feedback -int 1 # Play feedback when volume is changed


##################################################
# Safari & WebKit

defaults write com.apple.Safari UniversalSearchEnabled -bool false # Privacy: don’t send search queries to Apple
defaults write com.apple.Safari SuppressSearchSuggestions -bool true # Privacy: don’t send search queries to Apple
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true # Show the full URL in the address bar (note: this still hides the scheme)
defaults write com.apple.Safari HomePage -string "about:blank" # Set Safari’s home page to `about:blank` for faster loading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false # Prevent Safari from opening ‘safe’ files automatically after downloading
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true # Allow hitting the Backspace key to go to the previous page in history
defaults write com.apple.Safari ShowSidebarInTopSites -bool false # Hide Safari’s sidebar in Top Sites
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false # Make Safari’s search banners default to Contains instead of Starts With
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false # Disable auto-correct


##################################################
# Spotlight

sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes" # Disable Spotlight indexing for any volume that gets mounted and has not yet been indexed before.


##################################################
# Time Machine
# /Users/zthomps3/Library/Preferences/com.apple.TimeMachine.plist

sudo defaults write /Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true # Do not offer to use new disks for Time Machine


##################################################
# Software Updates
# /Library/Preferences/com.apple.SoftwareUpdate.plist

defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true # Automatically check for updates
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false # Automatically download new updates when available
defaults write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false # Automatically install macOS updates
defaults write com.apple.commerce AutoUpdate -bool false # Automatically install app updates from the App Store
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool false # Automatically install system data files and security updates
defaults write com.apple.SoftwareUpdate ConfigDataInstall -bool false # Automatically install system data files and security updates

# defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1 # Check for software updates daily, not just once per week
# defaults write com.apple.commerce AutoUpdateRestartRequired -bool true # Allow the App Store to reboot machine on macOS updates


##################################################
# Bluetooth

sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0 # Turn Bluetooth off


##################################################
# Security & Privacy

defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit -bool false # Share Mac Analytics
defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmitVersion -int 0
defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist ThirdPartyDataSubmit -bool false # Share with App Developers
defaults write /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist ThirdPartyDataSubmitVersion -int 0


##################################################
# Siri

defaults write com.apple.assistant.support.plist "Assistant Enabled" -bool false
defaults write com.apple.assistant.support.plist "Dictation Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri UserHasDeclinedEnable -bool true


##################################################
# Misc

defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false # Disable auto-correct

# Disable Guest User
/usr/bin/dscl . -delete /Users/Guest
/usr/bin/security delete-generic-password -a Guest -s com.apple.loginwindow.guest-account -D "application password" /Library/Keychains/System.keychain
# Also-do we need this still? (Should un-tick the box)
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool FALSE



##################################################
# Remote Management

defaults write /Library/Preferences/com.apple.RemoteManagement.plist LoadRemoteManagementMenuExtra -bool true
 
