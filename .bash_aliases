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
alias grep='grep --colour=always'

# Python aliases
alias python=python3
alias py=python3
alias pip=pip3

# Miscellaneous aliases
alias q=exit
alias ls='ls --color=auto'
alias new='konsole &'
alias ftp=lftp
alias music-dl="yt-dlp -ciwx --audio-format mp3 --embed-thumbnail --add-metadata -o \%\(title\)s.\%\(ext\)s"
alias ne="ne --utf8 --ansi --keys $TILDE_DIR/.ne/backspacefix.keys" # nice-editor

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
  # Use either a manually specified mountpoint or the default in /run
  if [ "$1" != "" ]; then
    mntdir="$1"
  else
    mntdir="/run/media/$(whoami)/Connor"
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
    adbfs "$mntdir" -o auto_unmount -o fsname=Connor
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
  else
    # Run Git as normal
    $git_exec "${@:1}"
  fi
}

volume() { # System volume adjustment/readback tool
  # NOTE: This uses amixer, so be sure to install alsa-utils.
  if [[ $1 == *-h* ]]; then  # Determine if "-h" appears in the argument. This matches -h and --help
    # Help text
    echo "Usage: ${FUNCNAME[0]} [value]"
    echo "Returns the current audio volume percentage, "
    echo "or if a percentage is provided, sets it to that value."
  elif [ $# -eq 0 ]; then
    # Output the current volume percentage if no argument was given

    # TODO: amixer is a tricksy gremlin.
    # Find a way to reliably determine current volume %, with or without amixer.
    echo "Volume readback not implemented"

    # Previous non-functional method, kept here as a starting point:
    #awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master)

    return
  elif ! [[ $1 =~ ^[-]?[0-9]+$ ]]; then  # Check argument is actually text rather than a number
    echo "${FUNCNAME[0]}: Input was not a number."
  elif [[ $1 -ge 0 && $1 -le 100 ]]; then  # If it's a number between 0 and 100, pass it to amixer
    amixer sset Master $1\%;
  else  # However, if it is not within that range, exit with an error.
    echo "${FUNCNAME[0]}: Input outside of range 0-100."
  fi
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
    printf '%s: ' "$file"
    (( $Y > 0 )) && printf '%d years ' $Y
    (( $D > 0 )) && printf '%d days ' $D
    (( $H > 0 )) && printf '%d hours ' $H
    (( $M > 0 )) && printf '%d minutes ' $M
    (( $Y > 0 || $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
    printf '%d seconds\n' $S
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

# Allows automatically installing a collection of packages that I would consider to be essential or useful
initial-setup() {
  # Check that a package manager has been detected.
  if [ ! "$PKG_MANAGER" ]; then
    __show_pkgmanager_error
    return
  fi

  # Verify that whiptail is available on the system
  if [ ! "$(command -v whiptail)" ]; then
    echo "Error: whiptail is not installed."
    return
  fi
  
  : <<'  END_COMMENT'
  # Warning message (only show for optionals/apps?)
  echo -e "WARNING!\nYou are about to install a lot of packages onto your machine.\nOf course, this will require a lot of patience and a decent internet connection.\nSome packages will need to be installed via Pip, and if you're\nusing Arch then an AUR helper such as paru or yay will be needed.\n"
  select answer in "Confirm" "Cancel"
  do
    case $answer in
      Confirm) break;;
      Cancel) return;;
    esac
  done
  echo "Proceeding"
  END_COMMENT

  # Manually ordered list of package categories
  local package_categories=(core pip optional apps)

  # Associative arrays to keep track of all packages and user selections
  declare -A packages
  declare -A selections
  
  # List of 'essential' packages, any tool used in this file should be listed here.
  packages[core]=$(echo "\
    bat\
    coreutils\
    ncurses\
    ack\
    nano\
    ne\
    neofetch\
    python3\
    python-pip\
    rsync\
    tar\
    wget\
  " | xargs)

  # Python packages that are useful to have. These are in their own category because pip is used to install them
  packages[pip]=$(echo "\
    pip_search\
  " | xargs)

  # List of 'nice-to-have' packages
  # Note; some of these are on the AUR, so it's useful to have a helper like paru or yay for those
  packages[optional]=$(echo "\
    adbfs-rootless-git\
    android-sdk-platform-tools\
    bc\
    cdrdao\
    dos2unix\
    downgrade\
    dvd+rw-tools\
    exfatprogs\
    ffmpeg\
    git\
    grub-customizer\
    htop\
    inetutils\
    iotop\
    lftp\
    lshw\
    lynx\
    make\
    mediainfo\
    net-tools\
    nmap\
    noto-fonts-cjk\
    noto-fonts-emoji\
    ntfs-3g\
    nvme-cli\
    scrcpy\
    screen\
    sox\
    speedtest-cli\
    tmux\
    tree\
    ttf-windows\
    unrar\
    unzip\
    xterm\
    youtube-dl\
    zip\
  " | xargs)
  
  # List of GUI applications
  packages[apps]=$(echo "\
    arduino\
    ark\
    atom\
    audacity\
    bitwarden\
    cool-retro-term\
    davinci-resolve\
    deja-dup\
    elisa\
    filelight\
    firefox\
    ghex\
    gimp\
    gnome-disk-utility\
    gwenview\
    kate\
    kdenlive\
    kompare\
    konsole\
    ksysguard\
    minecraft-launcher\
    obs-studio\
    partitionmanager\
    spectacle\
    speedcrunch\
    steam\
    teams\
    thunderbird\
    transmission-gtk\
    xfburn\
  " | xargs)
  
  # TODO: Show a menu to select categories with nested entries to fine-tune package selection.
  # TODO: For all selected packages from the aforementioned menu, attempt to install each one.
  
  # Automatically select all from core and pip
  auto_select_all=(core pip)
  for category in "${auto_select_all[@]}"; do
    selections[$category]=${packages[$category]}
  done
    
  # Main menu loop
  while true; do
    # Whiptail configurations
    local TITLE="Package Selection"
    local SIZE="$(( $LINES-20)) $(( $COLUMNS-20 )) $(( $LINES-30 ))" # Dynamic box size
    
    # Construct list of options to present to the user
    local menu_options="" # Clear list
    for category in "${package_categories[@]}"; do
      # Options for select/remove all
      [[ "${selections[$category]}" == "" ]] && toggleword="□Select" || toggleword="▣Remove" # Choose Remove or Select
      toggle=" ╔$toggleword all" # Weird space characters used to work around shell expansion
      # Append toggle to menu options
      menu_options+="${category}_all ${toggle} "
      # Also add the category entry
      menu_options+="$category $category "
    done
    menu_options=$menu_options"INSTALL -=Install=-"
    
    exec 3> /tmp/whiptail_stderr # Open an IO stream into a temporary file
    
    # Show the main menu, redirecting its stderr to our temporary file
    whiptail --notags\
      --backtitle "$TITLE" --title "$TITLE"\
      --ok-button "Select" --cancel-button "Abort"\
      --menu "Main menu" $SIZE\
      -- $menu_options 2>&3  # Standalone -- to escape the rest of the command
    
    wtcode=$? # Store the return code
    exec 3>&- # Close the IO stream
    
    # Detect if the Abort button was pressed
    if [[ $wtcode -ne 0 ]]; then
      return # Do not proceed
    fi
    
    # Read the temporary file into a variable and tidy up
    choice=$(tr -d '"' < /tmp/whiptail_stderr)
    rm /tmp/whiptail_stderr
    
    # Choice selection logic
    category=$(cut -f1 -d_ <<< $choice) # Strip _all from string
    if [[ "$choice" == "INSTALL" ]]; then
      # "INSTALL" choice should exit the loop, proceeding to install any packages
      break
    elif [[ "$choice" == *_all ]]; then
      # Choice ending in _all should select/remove all packages in the category
      if [ "${selections[$category]}" ]; then # Are there any selections present?
        # Yes, remove all.
        selections[$category]=
      else
        # No, add all
        selections[$category]=${packages[$category]}
      fi
    else
      # Anything else should display a checkbox menu for all the packages in that category
      TITLE="$TITLE"" > ""$category" # Append category name to whiptail title
      
      unset menu_options # Reset list of options
      i=0
      SAVEIFS=$IFS # Make a backup of the IFS
      IFS=' ' read -r -a array <<< "${packages[$category]}" # Split string into array
      for package in "${array[@]}"; do
        menu_options[i]=$(( i/3 )) # Entry number
        menu_options[i+1]="$package" # Package name

        # Having the menus remember what the user selected lines up with their expectation of persistency
        # A substring comparison matches selections against package name. It does *not* work the other way around.
        [[ "${selections[$category]}" == *"$package"* ]] && menu_options[i+2]="ON" || menu_options[i+2]="OFF"

        # Pad package name to create a margin on the right of the items
        menu_options[i+1]="${menu_options[i+1]}  "

        ((i+=3)) # Increment index counter
      done
      IFS=$SAVEIFS # Restore IFS to previous value
      
      exec 3> /tmp/whiptail_stderr # Open an IO stream into a temporary file
      
      # Show the package selection menu, redirecting its stderr to our temporary file
      whiptail --notags\
          --backtitle "$TITLE" --title "$TITLE"\
          --ok-button "Back" --nocancel\
          --checklist "Please select desired packages:" $SIZE\
          "${menu_options[@]}" 2>&3
      
      exec 3>&- # Close the IO stream
            
      # Read the temporary file into a variable and tidy up
      choices=$(tr -d '"' < /tmp/whiptail_stderr)
      rm /tmp/whiptail_stderr
      
      # Apply choices into the selections array
      selections[$category]=
      for ID in $choices; do
		# Parse the IDs returned by Whiptail back into package names
		name=${menu_options[$(( $ID*3+1 ))]}
		selections[$category]+="$name"
      done
    fi
      
  done
  
  # Install all selected packages
  # for p in selections
  for category in "${package_categories[@]}"; do # Iterate over package categories in a sensible order
    # Has the user selected any packages from that category?
    if [[ "${!selections[@]}" == *"$category"* ]]; then
      # Yes. Iterate over each selected package in that category
      SAVEIFS=$IFS # Make a backup of the IFS
      IFS=' ' read -r -a array <<< "${selections[$category]}" # Split string into array
      IFS=$SAVEIFS # Restore IFS to previous value
      for package in "${array[@]}"; do
        # Differentiate between pip category and everything else
        if [ "$category" == "pip" ]; then
          pip install --no-input --exists-action b $package
        else
          # Run standard fetch for anything else
          fetch -y $package
        fi
      done
    fi
  done
}
