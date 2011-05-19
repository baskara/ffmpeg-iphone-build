#!/bin/sh

./download-ffmpeg.sh
./fix-ffmpeg.sh
./build-ffmpeg-arm.sh
./build-ffmpeg-i386.sh
./combine-libs.sh
./install-libs.sh
