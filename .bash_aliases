#
# ~/.bash_aliases
#

# This file contains various functions and aliases I frequently use to make tasks significantly easier

# Package manager shortcuts
# Warning if package manager is undefined
if [ -z "$PKG_MANAGER" ]; then
	me=`basename "$0"`
	echo "$me: Warning - \$PKG_MANAGER is not set!"
fi
# Install one or more packages
fetch() {
	for package in "${@:1}"; do
		case $PKG_MANAGER in
			apt-get)
				sudo apt-get install "$package"
				;;
			pacman)
				sudo pacman -S "$package"
				;;
			*)
				echo Unsupported package manager \""$PKG_MANAGER"\"
				return
		esac
	done
}
# Remove one or more packages, as well as any orphaned dependencies associated with the package(s)
purge() {
	for package in "${@:1}"; do
		case $PKG_MANAGER in
			apt-get)
				sudo apt-get purge "$package"
				;;
			pacman)
				sudo pacman -Rs "$package";
				autoremove
				;;
			*)
				echo Unsupported package manager \""$PKG_MANAGER"\"
				return
		esac
	done
}
# Searches for one or more packages
findme() {
	for package in "${@:1}"; do
		case $PKG_MANAGER in
			apt-get)
				apt-cache search "$package"
				;;
			pacman)
				pacman -Ss "$package"
				;;
			*)
				echo Unsupported package manager \""$PKG_MANAGER"\"
				return
		esac
	done
}
# Syncs package database
update() {
	case $PKG_MANAGER in
		apt-get)
			sudo apt-get update
			;;
		pacman)
			sudo pacman -Syy
			;;
		*)
			echo Unsupported package manager \""$PKG_MANAGER"\"
	esac
}
# Performs an upgrade of all packages
upgrade() {
	case $PKG_MANAGER in
		apt-get)
			sudo apt-get upgrade
			;;
		pacman)
			sudo pacman -Syu
			;;
		*)
			echo Unsupported package manager \""$PKG_MANAGER"\"
	esac
}
# Automatically removes orphaned packages
autoremove() {
	case $PKG_MANAGER in
		apt-get)
			sudo apt-get autoremove
			;;
		pacman)
			unused=$(pacman -Qtdq)
			if [ -z "$unused" ]; then
				echo Nothing to do
			else
				sudo pacman -Rs $unused
			fi
			;;
		*)
			echo Unsupported package manager \""$PKG_MANAGER"\"
	esac
}

# Python aliases
alias python=python3
alias py=python3
alias pip=pip3
pip3() # Rest in peace 'pip3 search'.
{
	if [ "$1" == "search" ]; then
		# Run pip_search with the arguments, excluding the first two "pip search" words
		pip_search "${@:2}" | more;
	else
		pip3 "$@";
	fi
}

# Misc
alias q=exit
alias ls='ls --color=auto'
alias term='konsole &' #'gnome-terminal &'
alias new=term
alias ftp=lftp

# "MaKe and Change Directory"
mkcd() { mkdir -p "$@" && cd "$@"; }

# Its like cat but with syntax highlighting. pygmentize is part of the python-pygments package
#alias ccat='pygmentize -g -O style=monokai'
ccat()
{
	# Swap instances of 'pygmentize' in the stderr to the function name to avoid breaking the illusion
	# https://stackoverflow.com/questions/3618078/pipe-only-stderr-through-a-filter/52575087#52575087
	pygmentize -g -O style=monokai $@ 2> >(sed -e "s/pygmentize/${FUNCNAME[0]}/g" >&2)
}

# Force colour mode for less, ls, and grep
alias less='less -r'
alias ls='ls --color'
alias grep='grep --colour=always'

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

# Calculates the age of files/directories
when()
{
	# Check if no arguments were supplied
	if [ $# -eq 0 ]; then
		echo "Specify at least 1 file or directory."
		return 1;
	fi

	for file in "${@:1}"; do
		# Check if the file is even a file or directory
		if [[ ! (-f $file || -d $file) ]]; then
			echo $0: \'$file\' does not exist
			continue
		fi

		# Get the current Epoch and subtract the Epoch of the file
		local age=$(($(date +%s)-$(date -r "$file" +%s)))

		# https://unix.stackexchange.com/questions/27013/displaying-seconds-as-days-hours-mins-seconds
		# Tweaked to support years and output the name of the file in question
		local Y=$((age/365/60/60/24))
		local D=$((age/365/60/60%24))
		local H=$((age/60/60%24))
		local M=$((age/60%60))
		local S=$((age%60))
		printf '%s: ' "$file"
		(( $Y > 0 )) && printf '%d years ' $Y
		(( $D > 0 )) && printf '%d days ' $D
		(( $H > 0 )) && printf '%d hours ' $H
		(( $M > 0 )) && printf '%d minutes ' $M
		(( $Y > 0 || $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
		printf '%d seconds\n' $S
	done
}

# KDE lock/unlock/logout commands
alias lock='loginctl lock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias unlock='loginctl unlock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias logout='qdbus org.kde.ksmserver /KSMServer logout 0 0 0'
