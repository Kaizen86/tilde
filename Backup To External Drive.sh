#!/bin/bash
#Full backup script
#CAUTION - WILL REMOVE ALL FILES AT THE TARGET FOLDER BEFORE COPYING
drive=/media/$(whoami)/BACKUP
folder=UBUNTU

echo "External drive backup utility"

#Check if pv is installed
if ! command -v pv > /dev/null; then
	echo "Error: pv is missing!"
	echo "Running pacman..."
	sudo pacman -S pv --noconfirm
	#Check again after install
	if ! command -v pv > /dev/null; then
		echo "Failed to automatically install pv, aborting."
		exit 1
	fi
fi

#echo "Target drive is $drive"
#echo "Target folder path is $folder"

#Drive connected check
if [[ ! -d "$drive" ]]; then
	echo "Drive is not connected, aborting"
	exit 1
fi

backup="$drive/$folder"

#Target folder already exists - remove everything inside it
if [[ -d "$backup" ]]; then
	echo "Backup folder alread exists on drive, purging it."
	count=$(find "$backup" -type d,f | wc -l)
	rm -rfv $backup | pv -l -s $count > /dev/null
else
	echo "Making backup folder"
	mkdir "$backup"
fi

echo "Copying files..."
count=$(find ~ -type d,f | wc -l)
cp -rv ~ $backup | pv -l -s $count > /dev/null
#echo $count
echo "Done!"
