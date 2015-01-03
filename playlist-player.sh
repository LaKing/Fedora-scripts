#!/bin/bash

## this playlist-player script will play mp3's 
## starting a new list in 3 lanes, at 12h 17h 20h
## clvlc needed - install vlc

## working directory
WD=$(pwd)

## create autos-start
mkdir -p ~/.config/autostart

echo '[Desktop Entry]
Name=playlist-startup
GenericName=playlist-startup
Comment=Start the playlist up at login
Exec='$WD'/play.sh
Terminal=True
Type=Application
X-GNOME-Autostart-enabled=true' > ~/.config/autostart/playlist.desktop

## TODO
## run as a service 
## or implement singleton / mutex mechnism


LOGPATH="$WD/log"
MP3PATH="$WD/Music"
VARPATH="$WD/symlinks"

mkdir -p $LOGPATH
mkdir -p $VARPATH

function msg {
    NOW=$(date +%Y.%m.%d-%H:%M:%S)

    echo "$NOW $1"
    echo "$NOW $1" >> $LOGPATH/playlist.log
    echo "$NOW $1" >> $LOGPATH/vlc.log
}

msg "!! RESTART !!"

while true
do
	## full date
	NOW=$(date +%Y.%m.%d-%H:%M:%S)
	## hour
	Hr=$(date +%H)

#### get the DIR directory for the lanes
	## AM
	if [ "$Hr" -ge "8" ]
	then
	DIR="12"
	else
	DIR="20"
	fi

	## PM
	if [ "$Hr" -ge "17" ]
	then
	    DIR="17"
	    if [ "$Hr" -ge "20" ]
	    then
		DIR="20"
	    fi
	fi

	## dir for symlinks
	dir=$VARPATH/$DIR
	mkdir -p $dir

	## dir of audio files
	dira=$MP3PATH/$DIR
	
	## symlink file-list
	f=$(ls $dir | sort -R | tail -1 )

	cd $dir

	if [ "$f" == "" ]
	then 
	    n=$DIR"000"
	    msg "SYMLINKING"
	    for rf in $dira/*
	    do 
		    n=$((n+1))
		    #echo "Linking $rf" >> /home/x/playlist.log
		    ln -s "$rf" "$n.mp3"
	    done
	else
	    msg "START #$f - $(readlink $f)"
	    echo '' > $LOGPATH/vlc.log

	    ## play!
	    #cvlc --play-and-exit --quiet "$dir/$f" > /dev/null 2>&1	    
	    cvlc --verbose 2 --play-and-exit --album-art 0  "$dir/$f" &>> $LOGPATH/vlc.log
	    
	    msg "ENDED #$f"
	    echo "played: $f" >> $LOGPATH/vlc-history.log
	    rm -rf $f
	fi

done

