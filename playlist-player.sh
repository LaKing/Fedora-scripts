#!/bin/bash

## use mp3gain to normalize mp3 tracks
## find . -name *mp3 -exec mp3gain -a -k {} \;


## cvlc needed - install vlc

## working directory
WD=$(pwd)

function make_autostart {

## create autos-start
mkdir -p ~/.config/autostart

echo '[Desktop Entry]
Name=playlist-startup
GenericName=playlist-startup
Comment=Start the playlist up at login
Exec='$WD'/playlist-player.sh
Terminal=True
Type=Application
X-GNOME-Autostart-enabled=true' > ~/.config/autostart/playlist.desktop

}

## run as a service

function make_service {

echo '[Unit]
Description=Playlist-player

[Service]
User=x
Type=simple
ExecStart=/bin/bash /home/x/playlist-player.sh

[Install]
WantedBy=multi-user.target
' > /usr/lib/systemd/system/playlist.service

}

## make_autostart
## make_service


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

function get_3lane_dir {
## this playlist-player function will pick DIR of mp3's 
## starting a new list in 3 lanes, at 12h 17h 20h

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
}


    ## symlink file-list
    ## random string generator
    randa(){ < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;}

msg "!! RESTART !!"

while true
do
	## full date
	NOW=$(date +%Y.%m.%d-%H:%M:%S)
	## hour
	Hr=$(date +%H)

	#### get the DIR directory for the lanes
	DIR=""
	
	get_3lane_dir

	## dir for symlinks
	dir=$VARPATH/$DIR
	mkdir -p $dir

	## dir of audio files
	dira=$MP3PATH/$DIR
	
	## symlink file-list
	f=$(ls $dir | sort -R | tail -1 )

    if [ "$f" == "" ]
    then 
        msg "SYMLINKING"

        find $dira -name '*.mp3' -or -name '*.wav' > $WD/playlist.txt

	while read f
	do 
	    echo "Symlinking $f"
	    ln -s "$f" $VARPATH/$(randa).mp3
	done < $WD/playlist.txt
        
    else
        msg "START #$f - $(readlink $dir/$f)"
        echo '' > $LOGPATH/vlc.log

        ## play!
        #cvlc --play-and-exit --quiet "$dir/$f" > /dev/null 2>&1	    
        cvlc --verbose 2 --play-and-exit --album-art 0  "$dir/$f" #&>> $LOGPATH/vlc.log

        msg "ENDED #$f"
        echo "played: $f" >> $LOGPATH/vlc-history.log
        rm -rf $f
        sleep 1
    fi


done

