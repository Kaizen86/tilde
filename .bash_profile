#
# ~/.bash_profile
#

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

[[ -f "$SCRIPT_DIR/.bashrc" ]] && . "$SCRIPT_DIR/.bashrc"
