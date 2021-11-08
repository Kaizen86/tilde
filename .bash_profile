#
# ~/.bash_profile
#

# Fallback file for login shells

# Determine script directory
export TILDE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

[[ -f "$TILDE_DIR/.bashrc" ]] && . "$TILDE_DIR/.bashrc"
