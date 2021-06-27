#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

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

# Run the aliases file if it exists
if [ -f "$HOME/.bash_aliases" ]; then
	. "$HOME/.bash_aliases"
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

# Use a colour prompt if available, otherwise use the colourless version
if [ "$colour_prompt" = yes ]; then
	if [ "$(whoami)" = root ]; then
		# Modified version so username turns red if the user is root
		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u\[\033[01;32m\]@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
	else
		# Normal colour scheme
		PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
	fi
else
	# No colours :(
	PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
# Old prompt
#PS1='[\u@\h \W]\$ '

# Extend the PATH to include pip programs
export PATH=$PATH:/home/daniel/.local/bin

# Use Nano as the default editor
export EDITOR=/usr/bin/nano
export VISUAL=$EDITOR # crontab uses a different var, so set that too.

# Add 'thefuck' alias
eval "$(thefuck --alias)"
