#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Run neofetch if the shell is over SSH
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
	neofetch
fi

# Determine the system's package manager
declare -A osInfo;
osInfo[/etc/redhat-release]=yum
osInfo[/etc/arch-release]=pacman
osInfo[/etc/gentoo-release]=emerge
osInfo[/etc/SuSE-release]=zypp
osInfo[/etc/debian_version]=apt-get
for f in ${!osInfo[@]}
do
	if [[ -f $f ]]; then
		PKG_MANAGER=${osInfo[$f]};
	fi
done

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Run the aliases file if it exists
if [ -f "$SCRIPT_DIR/.bash_aliases" ]; then
	. "$SCRIPT_DIR/.bash_aliases"
fi

# Test for the existence of tput, which is necessary for colours.
if [ -x /usr/bin/tput ]; then
	# It exists, let's run it!
	tput setaf 1 >&/dev/null
	colour_prompt=yes # This variable determines whether the prompt will include colour ANSI codes
else
	# Colours are *not* supported
	colour_prompt=no
fi

# Define prompt as USER@HOST:PATH$
# Use a colour prompt if available, otherwise use the colourless version
if [ "$colour_prompt" = yes ]; then
	# Select colour for the username section of the prompt
	case $(whoami) in
		daniel)
			# CYAN
			USER_COLOUR=$(echo -en '\033[01;36m')
			;;
		root)
			# RED
			USER_COLOUR=$(echo -en '\033[01;31m')
			;;
		*) # Unrecognised user
			# LIME
			USER_COLOUR=$(echo -en '\033[01;32m')
	esac

	# Select colour for the hostname section of the prompt
	case $(hostname) in
		daniel-tower)
			# CYAN
			DEVICE_COLOUR=$(echo -en '\033[01;36m')
			;;
		daniel-laptop)
			# YELLOW
			DEVICE_COLOUR=$(echo -en '\033[01;33m')
			;;
		raspberrypi)
			# DARK PINK
			DEVICE_COLOUR=$(echo -en '\033[01;31m')
			;;
		*) # Unrecognised device
			# LIME
			DEVICE_COLOUR=$(echo -en '\033[01;32m')
	esac

	PS1='${debian_chroot:+($debian_chroot)}\[$USER_COLOUR\]\u\[\033[01;32m\]@\[$DEVICE_COLOUR\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
	# No colours :(
	PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Extend the PATH to include pip programs
export PATH=$PATH:/home/daniel/.local/bin
# Extend the PATH to include the Android SDK tools
export PATH=$PATH:/opt/android-sdk/platform-tools

# Use Nano as the default editor
export EDITOR=/usr/bin/nano
export VISUAL=$EDITOR # crontab uses a different var, so set that too.

# Add 'thefuck' alias if it's installed on the system.
if command -v thefuck &> /dev/null; then
	eval "$(thefuck --alias)"
fi
