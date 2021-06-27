#
# ~/.bash_aliases
#

# This file contains various functions and aliases

# Package manager shortcuts

# Warning if package manager is undefined
if [ -z "$PKG_MANAGER" ]; then
	me=`basename "$0"`
	echo "$me: Warning - $PKG_MANAGER is not set!"
fi

gimme() {
	for package in "${@:1}"; do
		if [ "$PKG_MANAGER" = "apt-get" ]; then
			sudo apt-get install "$package"
		elif [ "$PKG_MANAGER" = "pacman" ]; then
			sudo pacman -S "$package"
		else
			echo Unsupported package manager \""$PKG_MANAGER"\"
			return
		fi
	done
}

purge() {
	for package in "${@:1}"; do
		if [ "$PKG_MANAGER" = "apt-get" ]; then
			sudo apt-get purge "$package"
		elif [ "$PKG_MANAGER" = "pacman" ]; then
			sudo pacman -Rs "$package";
			autoremove
		else
			echo Unsupported package manager \""$PKG_MANAGER"\"
			return
		fi
	done
}

findme() {
	for package in "${@:1}"; do
		if [ "$PKG_MANAGER" = "apt-get" ]; then
			apt-cache search "$package"
		elif [ "$PKG_MANAGER" = "pacman" ]; then
			pacman -Ss "$package"
		else
			echo Unsupported package manager \""$PKG_MANAGER"\"
			return
		fi
	done
}

update() {
	if [ "$PKG_MANAGER" = "apt-get" ]; then
		sudo apt-get update
	elif [ "$PKG_MANAGER" = "pacman" ]; then
		sudo pacman -Syy
	else
		echo Unsupported package manager \""$PKG_MANAGER"\"
	fi
}

upgrade() {
	if [ "$PKG_MANAGER" = "apt-get" ]; then
		sudo apt-get upgrade
	elif [ "$PKG_MANAGER" = "pacman" ]; then
		sudo pacman -Syu
	else
		echo Unsupported package manager \""$PKG_MANAGER"\"
	fi
}

autoremove() {
	if [ "$PKG_MANAGER" = "apt-get" ]; then
		sudo apt-get autoremove
	elif [ "$PKG_MANAGER" = "pacman" ]; then
		sudo pacman -Rs $(pacman -Qtdq)
	else
		echo Unsupported package manager \""$PKG_MANAGER"\"
	fi
}

# Python aliases
alias python=python3
alias py=python3
alias pip=pip3
pip3() # Rest in peace 'pip3 search'.
{
	if [ $1 == "search" ]; then
		command pip_search "${@:2}" | more;
	else
		command pip3 "$@";
	fi
}

# Misc
alias q=exit
alias ls='ls --color=auto'
mkcd() { mkdir -p "$@" && cd "$@"; }
alias term='konsole &' #'gnome-terminal &'
alias new=term
# Its like cat but with syntax highlighting. pygmentize is part of the python-pygments package
alias ccat='pygmentize -g -O style=monokai'
# Always make less decode ANSI colour codes
alias less='less -r'

# System volume adjustment/readback tool
# NOTE: This uses amixer, so be sure to install alsa-utils.
volume()
{
	if [[ $1 == *-h* ]]; then  # Determine if "-h" appears in the argument. This matches -h and --help
		# Help text
		echo "Usage: ${FUNCNAME[0]} [value]"
		echo "Returns the current audio volume percentage, "
		echo "or if a percentage is provided, sets it to that value."
	elif [ $# -eq 0 ]; then
		# Output the current volume percentage if no argument was given

		# When in doubt, steal from the internet because somebody smarter than you has probably done it before.
		# https://unix.stackexchange.com/questions/89571/how-to-get-volume-level-from-the-command-line
		awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master)

		return
	elif ! [[ $1 =~ ^[-]?[0-9]+$ ]]; then  # Check argument is actually text rather than a number
		echo "${FUNCNAME[0]}: Input was not a number."
	elif [[ $1 -ge 0 && $1 -le 100 ]]; then  # If it's a number between 0 and 100, pass it to amixer
		amixer sset Master $1\%;
	else  # However, if it is not within that range, exit with an error.
		echo "${FUNCNAME[0]}: Input outside of range 0-100."
	fi
}

# KDE lock/unlock/logout commands
alias lock='loginctl lock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias unlock='loginctl unlock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias logout='qdbus org.kde.ksmserver /KSMServer logout 0 0 0'
