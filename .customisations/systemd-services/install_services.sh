#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Make sure we're being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Iterate over all .service files in the current directory
for file in $SCRIPT_DIR/*.service; do
	# Determine destination path
	dest=/etc/systemd/system/"$(basename "$file")"

	# Skip files that are already present
	if [ -f "$dest" ]; then
		echo "Skipping $file"
		continue
	fi

	# Make a symbolic link into the correct folder
	ln -vsT "$file" "$dest"
done

# Reload list of services
systemctl daemon-reload
