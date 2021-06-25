# Apt aliases
alias gimme='sudo pacman -S'
alias purge='sudo pacman -Rs'
findme() {
	for var in "$@"
	do
		pacman -Ss "$var"
	done
}
alias update='sudo pacman -Syy'
alias upgrade='sudo pacman -Syu'
#alias cleanup='sudo apt-get autoremove'

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
END-COMMENT

# KDE lock/unlock/logout commands
alias lock='loginctl lock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias unlock='loginctl unlock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias logout='qdbus org.kde.ksmserver /KSMServer logout 0 0 0'
