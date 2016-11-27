#!/bin/bash

## This script needs the youtube-dl package

if [ -z "$1" ]
then
    echo "youtube URL?"
    exit
fi

url=$1

if youtube-dl $url
then
    echo "Download OK"
else
    echo "Download ERROR"
    exit
fi

tag=${url:32}

echo "youtube video: $tag"

mp4="$(ls | grep $tag.mp4)"

echo "convert $mp4"
wav="${mp4:0:-4}.wav"

rm -rf "$wav"
if ffmpeg -i "$mp4" "$wav"
then
    echo "Conversion OK"
else
    echo "Conversion ERROR"
    exit
fi

rm -rf "$mp4"

echo "Ready"
