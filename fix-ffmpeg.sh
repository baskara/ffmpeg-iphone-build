#!/bin/sh

cp ffmpeg/Makefile ffmpeg/Makefile.bak
sed 's/\-number//g' ffmpeg/Makefile.bak > ffmpeg/Makefile
