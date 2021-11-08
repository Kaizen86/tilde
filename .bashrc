#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Run neofetch if the shell is over SSH
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  neofetch
fi

# Detect and warn about problematic locale
[ "$LANG" == C ] && echo "Warning - Your locale is set to C. This can cause issues in some programs."

# Me increasing the history file limit tenfold:
# https://www.youtube.com/watch?v=VtJUHGjVm0E
HISTFILESIZE=5000
shopt -s histappend # Append to the history file, don't overwrite it

# Determine script directory
export TILDE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Extend the PATH to include additional folders
export PATH=$PATH:"$TILDE_DIR"/.local/bin

# Ensure GPG is configured correctly
export GPG_TTY=$(tty)

declare -A osInfo; # Associative array to match files with a package manager
# Short list of possible release files and what package manager they indicate
  osInfo[/etc/arch-release]=pacman #Arch
  osInfo[/etc/debian_*]=apt-get #debian
  # The rest of these are examples, I don't use any of these.
  #osInfo[/etc/fedora-release]=dnf #Fedora
  #osInfo[/etc/gentoo-release]=emerge #Gentoo
  #osInfo[/etc/novell-release]=zypper #SuSE
  #osInfo[/etc/redhat*]=yum #Red Hat Enterprise Linux
  #osInfo[/etc/sles-release]=zypper #SuSE
  #osInfo[/etc/SuSE-release]=zypper #SuSE
  #osInfo[/etc/synoinfo.conf]=synopkg #Synology
for f in ${!osInfo[@]} # Iterate over each entry
do
  if [[ -f $f ]]; then # Test for the file in question
    PKG_MANAGER=${osInfo[$f]} # Read the value from the array
    break # We're done here.
  fi
done
unset osInfo # We don't need this anymore

# Run the aliases file if it exists
[ -f "$TILDE_DIR/.bash_aliases" ] && . "$TILDE_DIR/.bash_aliases"

# Test for the existence of tput, which is necessary for colours.
if [ -x /usr/bin/tput ]; then
  # It exists, let's run it!
  tput setaf 1 >&/dev/null
  COLOURS_SUPPORTED=yes # Remember that we enabled tput
else
  echo "Warning - tput not detected. Fancy prompt will be disabled."
  COLOURS_SUPPORTED=no
fi

# Define prompt as USER@HOST:PATH$
# Use a colour prompt if possible, otherwise use the plain version
if [ "$COLOURS_SUPPORTED" = yes ]; then
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
  case $HOSTNAME in
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
  # Plain version for the rare event that colours aren't supported
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Set the default editor
export EDITOR=/usr/bin/nano
export VISUAL=$EDITOR # Crontab uses a different variable
