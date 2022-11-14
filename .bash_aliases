#
# ~/.bash_aliases
#

# This file contains a plethora of aliases and functions I frequently use

# Package manager shortcuts
# Warning if package manager is undefined
if [ -z "$PKG_MANAGER" ]; then
  echo "Warning - \$PKG_MANAGER is not set! Your distro isn't supported at the moment."
fi

# Force colour mode for less, ls, and grep
alias less='less -r'
alias ls='ls --color'
alias l='ls --color'
alias la='ls --color -la'
alias grep='grep --colour=always'

# Python aliases
alias python=python3
alias py=python3
alias pip=pip3

# Miscellaneous aliases
alias q=exit
alias cd..="echo -e '\"git status\" FTFY ;)'; cd .." # Missing the space is a somewhat common typo for me
alias new='konsole &'
alias ftp=lftp
alias music-dl='yt-dlp -ciwx --audio-format mp3 --embed-thumbnail --add-metadata -o \%\(title\)s.\%\(ext\)s'
alias open=xdg-open

# Hide ffmpeg (and similar) banners
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias ffplay='ffplay -hide_banner'

# KDE session management aliases
alias lock='loginctl lock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias unlock='loginctl unlock-session $(loginctl show-seat seat0 | grep ActiveSession | cut -d'=' -f 2)'
alias logout='qdbus org.kde.ksmserver /KSMServer logout 0 0 0'

# === Function definitions past this point ===

# "MaKe and Change Directory"
mkcd() { mkdir -p "$@" && cd "$@"; }

# HighLight function for ack with passthrough
if [ -x "$(command -v ack)" ]; then
  hl() {
    ack --passthru $@
  }
else
  echo "Warning - ack is not installed. 'hl' will not provide colours."
  hl() {
    cat # Just so that it will at least show output
  }
fi

if ! [ -x "$(command -v pip_search)" ]; then
  echo "Warning - pip_search is not installed. 'pip3 search' will not function."
fi
pip3() { # Rest in peace 'pip3 search'.
  if [ "$1" == "search" ]; then
    # Run pip_search with the remaining arguments, piped into more.
    pip_search "${@:2}" | more
  else
    # Execute pip3 as normal
    local pip_exec=$(which pip3) # Determine path to pip3
    $pip_exec "$@"
  fi
}


init-adbfs() { # "Initialise ADBFS"
  fsname=Connor
  # Use either a manually specified mountpoint or the default in /run
  if [ "$1" != "" ]; then
    mntdir="$1"
  else
    mntdir="/run/media/$(whoami)/$fsname"
  fi

  # Make the folder if it doesn't exist
  if [ ! -d "$mntdir" ]; then
    sudo mkdir "$mntdir" # Root must make it...
    # But the current user must then own it.
    sudo chown $(whoami) "$mntdir"
  fi
  # Double check if it worked
  if [ -d "$mntdir" ]; then
    # It did, proceed.
    adbfs "$mntdir" -o auto_unmount -o fsname="$fsname"
  else
    # Error message
    echo "Aborting, mountpoint couldn't be created."
  fi
}

git() { # Git shortcuts
  local git_exec=$(which git) # Determine path to git
  if [ "$1" == "clone" ]; then
    # Clone the repository then cd into it
    $git_exec clone "${@:2}" && cd "$(basename "$2" .git)"
  elif [ "$1" == "tree" ]; then
    # Fancier git logs
    $git_exec log --graph --decorate --abbrev-commit --pretty=medium --branches --remotes "${@:2}"
  elif [[ "$1" =~ ^stst* ]]; then
    # This is a common typo for me when trying to type "status"
    echo -e "\"git status\" FTFY ;)\n"
    $git_exec status
  else
    # Run Git as normal
    $git_exec "${@:1}"
  fi
}

volume() { # System volume adjustment/readback tool
  # NOTE: This uses amixer, so be sure to install alsa-utils.
  if [[ $1 == *-h* ]]; then  # Determine if "-h" appears in the argument. This matches -h and --help
    # Help text
    echo "Usage: ${FUNCNAME[0]} [value/keyword]"
    echo "Returns the current amixer configuration for the Master mixer,"
    echo "or if a percentage is provided, sets the volume to that value."
    echo "The mixer may also be muted with the keywords \"mute\" and \"unmute\"."
  elif [ $# -eq 0 ]; then
    # Output the current volume settings
    amixer sget Master
  elif ! [[ $1 =~ ^[-]?[0-9]+$ ]]; then  # Check argument is actually text rather than a number
    # If it was, then check if it is equal to "mute" or "unmute".
    if [[ $1 =~ ^(un)?mute$ ]]; then
      amixer set Master $1
    else
      # They've given us nonsense - exit with an error
      echo "${FUNCNAME[0]}: Input was not a number or recognised keyword."
      return 1
    fi
  elif [[ $1 -ge 0 && $1 -le 100 ]]; then  # If it's a number between 0 and 100, pass it to amixer
    amixer sset Master $1\%;
  else  # However, if it is not within that range, exit with an error.
    echo "${FUNCNAME[0]}: Input outside of range 0-100."
  fi
  return 0
}

when() { # Calculates the age of files/directories and displays it in a human-readable format
  # Parse the first argument, if any.
  case "$1" in

    --help)
      echo "Usage: ${FUNCNAME[0]} [OPTION] FILES
Displays a human-readable time since the created/accessed/modified field of files and folders.

Options:
  -c, --created           Time since file creation
  -a, --accessed          Time since last file access
  -m, --modified          Time since last modification (default mode)
  -s, --statuschanged     Time since last status change"
      return 0
      ;;

    -c|--created)
      #  %W   time of file birth, seconds since Epoch; 0 if unknown
      local format_code=%W
      shift
      ;;
    -a|--accessed)
      #  %X   time of last access, seconds since Epoch
      local format_code=%X
      shift
      ;;
    -m|--modified)
      # Use the modified time by default
      local format_code=%Y
      shift
      ;;
    -s|--statuschanged)
      #  %Z   time of last status change, seconds since Epoch
      local format_code=%Z
      shift
      ;;
    -*)
      echo "${FUNCNAME[0]}: unrecognised option '$1'
Try '${FUNCNAME[0]} --help' for more information"
      return 1
      ;;
    *)
      # First argument is a filename, use the Last Modified value by default.
      #  %Y   time of last data modification, seconds since Epoch
      local format_code=%Y
      ;;
  esac

  # Check if no files were supplied
  if [ $# -eq 0 ]; then
    echo "${FUNCNAME[0]}: specify at least 1 file or folder.
Try '${FUNCNAME[0]} --help' for more information"
    return 1
  fi

  for file in "${@:1}"; do
    # Check if the file is even a file or directory
    if [[ ! (-f "$file" || -d "$file") ]]; then
      echo ${FUNCNAME[0]}: \'$file\' does not exist
      continue
    fi

    # Use stat to read the file's age field, according to which one the user wants.
    local file_epoch=$(stat -c$format_code "$file")
    # Is it 0? That means there was an error, usually.
    if [ $file_epoch -eq 0 ]; then
      printf '%s: <UNKNOWN>\n' "$file"
      continue
    fi

    # Get the current Epoch and subtract the Epoch of the file
    local age=$(( $(date +%s) - $file_epoch ))

    # https://unix.stackexchange.com/questions/27013/displaying-seconds-as-days-hours-mins-seconds
    # Tweaked to support years and to output the name of the file in question
    local Y=$((age/60/60/24/365))
    local D=$((age/60/60/24%365))
    local H=$((age/60/60%24))
    local M=$((age/60%60))
    local S=$((age%60))
    # Determine if the units are plural
    [[ $Y == 1 ]] && Yp="" || Yp="s"
    [[ $D == 1 ]] && Dp="" || Dp="s"
    [[ $H == 1 ]] && Hp="" || Hp="s"
    [[ $M == 1 ]] && Mp="" || Mp="s"
    [[ $S == 1 ]] && Sp="" || Sp="s"
    # Output results
    printf '%s: ' "$file"
    (( $Y > 0 )) && printf '%d year%s, ' $Y $Yp
    (( $D > 0 )) && printf '%d day%s, ' $D $Dp
    (( $H > 0 )) && printf '%d hour%s, ' $H $Hp
    (( $M > 0 )) && printf '%d minute%s, ' $M $Mp
    (( $Y > 0 || $D > 0 || $H > 0 || $M > 0 )) && printf '\b\b and '
    printf '%d second%s\n' $S $Sp
  done
}


# Package management functions

__show_pkgmanager_error() { # Hidden function that shows a message explaining how to correct unsupported PKG_MANAGER issues
  echo -e "Error: no compatible package manager was detected. This is caused by a lack of support for your distro's package manager.\n\nTo fix this, navigate to the section in .bashrc responsible for setting \$PKG_MANAGER and uncomment the appropriate line.\nThen, extend the functionality of the package management functions contained in .bash_aliases.\nOnce these steps are done, reload the changes either through the source command or by restarting the terminal.\n\nPlease submit consider submitting extensions you make to the repo, that would be greatly appreciated!"
}

__pkgmanagement_noconfirm_flag() { # Returns the flag used by the system package manager for skipping confirmation prompts
  case $PKG_MANAGER in
    apt-get)
      echo "-y"
      ;;
    pacman)
      echo "--noconfirm"
      ;;
  esac
}

fetch() { # Installs packages
  # Parse the first argument, if any.
  case "$1" in
    --help)
      echo "Usage: ${FUNCNAME[0]} [OPTION] PACKAGES
Installs one or more packages, optionally autonomously.
Part of a collection of functions to abstract the underlying system package manager into universal commands

Options: (Use at your own risk, these are intended for scripting)
  -y, --yestoall           Bypass confirmation prompts by supplying a flag to suppress them."
      return 0
      ;;

    -y|--yestoall)
      local noconfirm=$(__pkgmanagement_noconfirm_flag)
      shift
      ;;
    -*)
      echo "${FUNCNAME[0]}: unrecognised option '$1'
Try '${FUNCNAME[0]} --help' for more information"
      return 1
      ;;
  esac
  
  # Run appropriate command
  case $PKG_MANAGER in
    apt-get)
      sudo apt-get install $noconfirm "${@:1}"
      ;;
    pacman)
      sudo pacman -S $noconfirm "${@:1}"
      ;;
    *)
      __show_pkgmanager_error
  esac
}
purge() { # Removes packages, as well as any orphaned dependencies
# Parse the first argument, if any.
  case "$1" in
    --help)
      echo "Usage: ${FUNCNAME[0]} [OPTION] PACKAGES
Removes one or more packages and any unused dependencies, optionally autonomously.
Part of a collection of functions to abstract the underlying system package manager into universal commands

Options: (Use at your own risk, these are intended for scripting)
  -y, --yestoall           Bypass confirmation prompts by supplying a flag to suppress them."
      return 0
      ;;

    -y|--yestoall)
      local noconfirm=$(__pkgmanagement_noconfirm_flag)
      shift
      ;;
    -*)
      echo "${FUNCNAME[0]}: unrecognised option '$1'
Try '${FUNCNAME[0]} --help' for more information"
      return 1
      ;;
  esac
  
  # Run appropriate command
  case $PKG_MANAGER in
    apt-get)
      sudo apt-get purge $noconfirm "${@:1}"
      ;;
    pacman)
      sudo pacman -Rs $noconfirm "${@:1}";
      ;;
    *)
      __show_pkgmanager_error
  esac
}
findme() { # Searches for packages in the local database
  for package in "${@:1}"; do
    case $PKG_MANAGER in
      apt-get)
        apt-cache search "$package" | hl "$package"
        ;;
      pacman)
        pacman -Ss "$package" | hl "$package"
        ;;
      *)
        __show_pkgmanager_error
    esac
  done
}
update() { # Synchronises local package database
  case $PKG_MANAGER in
    apt-get)
      sudo apt-get update
      ;;
    pacman)
      sudo pacman -Syy
      ;;
    *)
      __show_pkgmanager_error
  esac
}
upgrade() { # Performs an upgrade of all packages
# Parse the first argument, if any.
  case "$1" in
    --help)
      echo "Usage: ${FUNCNAME[0]} [OPTION] PACKAGES
Upgrades all outdated packages, optionally autonomously.
Part of a collection of functions to abstract the underlying system package manager into universal commands

Options: (Use at your own risk, these are intended for scripting)
  -y, --yestoall           Bypass confirmation prompts by supplying a flag to suppress them."
      return 0
      ;;

    -y|--yestoall)
      local noconfirm=$(__pkgmanagement_noconfirm_flag)
      shift
      ;;
    -*)
      echo "${FUNCNAME[0]}: unrecognised option '$1'
Try '${FUNCNAME[0]} --help' for more information"
      return 1
      ;;
  esac
  
  # Run appropriate command
  case $PKG_MANAGER in
    apt-get)
      sudo apt-get $noconfirm upgrade
      ;;
    pacman)
      sudo pacman $noconfirm -Syu
      ;;
    *)
      __show_pkgmanager_error
  esac
}
autoremove() { # Automatically removes orphaned packages
# Parse the first argument, if any.
  case "$1" in
    --help)
      echo "Usage: ${FUNCNAME[0]} [OPTION] PACKAGES
Removes any unused packages, optionally autonomously.
Part of a collection of functions to abstract the underlying system package manager into universal commands

Options: (Use at your own risk, these are intended for scripting)
  -y, --yestoall           Bypass confirmation prompts by supplying a flag to suppress them."
      return 0
      ;;

    -y|--yestoall)
      local noconfirm=$(__pkgmanagement_noconfirm_flag)
      shift
      ;;
    -*)
      echo "${FUNCNAME[0]}: unrecognised option '$1'
Try '${FUNCNAME[0]} --help' for more information"
      return 1
      ;;
  esac
  
  # Run appropriate command
  case $PKG_MANAGER in
    apt-get)
      sudo apt-get $noconfirm autoremove
      ;;
    pacman)
      unused=$(pacman -Qtdq)
      if [ -z "$unused" ]; then
        echo Nothing to do
      else
        sudo pacman $noconfirm -Rs $unused
      fi
      ;;
    *)
      __show_pkgmanager_error
  esac
}
