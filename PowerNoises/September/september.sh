#!/bin/bash
#Executed on system boot.

date=$(date "+%m %d") #Get current date

#Check if the date is September 21st
if [ "$date" == "09 21" ]; then
	#If it is, turn the speakers on and play a particular music track
	amixer sset Master 50\%;
	aplay $(dirname "$0")/September.wav
fi
