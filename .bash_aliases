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

<< 'END-COMMENT'
	I have temporarily removed this because the volume
	readback is returning values too low due to frankly
	illogical values being returned from amixer.
	(Why the hell is the Maximum 87???)
	Until I work out a way to scale the values to something
	reasonable, this has been put in the time-out corner.
	
	It's not completely broken, mind. The ability to update
	the volume level works perfectly. Just the readback
	is wonky. If you only care about changing the volume,
	feel free to re-enable this.

	Aight peace ooouuuttt
	
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

		# I'll be honest, I have no idea what that sed is doing.
		# Somehow it removes the extraneous lines by combining the noprint option with the /p print command and a mystery regex.
		# It leaves us with a single line, something that looks like
		#  : values=30

		# The following cut command is much more straightforward; it removes
		# everything up to and including the equals sign, leaving just the number.

		echo $(amixer cget name='Master Playback Volume' | sed -n '/ v/p' | cut -d= -f2)%
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
