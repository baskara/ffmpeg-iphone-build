#!/bin/sh

if [ -d ffmpeg ]
then
    cd ffmpeg
    echo "Updating ffmpeg..."
    svn update
    cd -
else
    echo "Pulling ffmpeg..."
    svn co svn://svn.ffmpeg.org/ffmpeg/trunk ffmpeg
fi


