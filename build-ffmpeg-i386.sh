#!/bin/bash

set -e

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )

DIST_DIR_BASE=${DIST_DIR_BASE:="$SCRIPT_DIR/dist"}

unset DEVROOT
unset SDKVER
unset SDKROOT
unset ARCH
unset CC
unset NM
unset AS
unset CFLAGS
unset DIST_DIR
unset EXTRA_CC_FLAGS
unset EXTRA_LDFLAGS
unset CONFIGURE_OPTIONS

export DEVROOT="`xcode-select -print-path`/Platforms/iPhoneSimulator.platform/Developer"
export SDKVER=`xcodebuild -showsdks | grep iphoneos | sort | tail -n 1 | awk '{ print $2}' `
export SDKROOT="$DEVROOT/SDKs/iPhoneSimulator$SDKVER.sdk"

export ARCH="i386"
export CC="$DEVROOT/usr/bin/gcc"
export NM="$DEVROOT/usr/bin/nm"
export AS="$CC"
export CFLAGS="-arch $ARCH -isysroot $SDKROOT"

FFMPEG_DIR=ffmpeg-$ARCH
rm -rf $FFMPEG_DIR
cp -a ffmpeg $FFMPEG_DIR

cd $FFMPEG_DIR

for i in $SCRIPT_DIR/patches/ffmpeg/*
do
    patch -p0 < $i
done

DIST_DIR=$DIST_DIR_BASE-$ARCH
mkdir -p $DIST_DIR

CONFIGURE_OPTIONS="--enable-gpl --enable-postproc --enable-swscale --enable-avfilter"
CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --extra-ldflags=-L$DIST_DIR/lib --extra-cflags=-I$DIST_DIR/include"
EXTRA_FLAGS="--enable-cross-compile --target-os=darwin --arch=$ARCH"
EXTRA_CC_FLAGS="-mdynamic-no-pic -isysroot $SDKROOT"
EXTRA_LDFLAGS="-arch $ARCH -isysroot $SDKROOT"

./configure --cc="$CC" --disable-bzlib --disable-mmx --disable-ffmpeg --disable-ffplay --disable-ffserver --as="$SCRIPT_DIR/gas-preprocessor.pl $AS" --nm="$NM" --sysroot=$SDKROOT $EXTRA_FLAGS --extra-ldflags="$EXTRA_LDFLAGS" --extra-cflags="$EXTRA_CFLAGS" --prefix=$DIST_DIR $CONFIGURE_OPTIONS

make && make install

