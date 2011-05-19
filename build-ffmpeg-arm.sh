#!/bin/sh

set -e

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )

DIST_DIR_BASE=${DIST_DIR_BASE:="$SCRIPT_DIR/dist"}

PATH=$SCRIPT_DIR:$PATH


unset DEVROOT
unset SDKVER
unset SDKROOT
unset ARCH
unset ARCHS
unset CC
unset NM
unset AS
unset CFLAGS
unset DIST_DIR
unset EXTRA_CC_FLAGS
unset EXTRA_LDFLAGS
unset CONFIGURE_OPTIONS

export DEVROOT="`xcode-select -print-path`/Platforms/iPhoneOS.platform/Developer"
export SDKVER=`xcodebuild -showsdks | grep iphoneos | sort | tail -n 1 | awk '{ print $2}' `
export SDKROOT="$DEVROOT/SDKs/iPhoneOS$SDKVER.sdk"

export CC="$DEVROOT/usr/bin/gcc"
export CPP="$DEVROOT/usr/bin/cpp"
export AS="$CC"
export NM="$DEVROOT/usr/bin/nm"

export ARCHS="armv6 armv7"

for ARCH in $ARCHS
do


    export FFMPEG_DIR="ffmpeg-$ARCH"
    rm -rf $FFMPEG_DIR
    cp -a ffmpeg $FFMPEG_DIR

    cd $FFMPEG_DIR

    for i in $SCRIPT_DIR/patches/ffmpeg/*
    do
        patch -p0 < $i
    done

    DIST_DIR=$DIST_DIR_BASE-$ARCH
    mkdir -p $DIST_DIR

    # Default configure options
    CONFIGURE_OPTIONS="--enable-gpl --enable-postproc --enable-swscale --enable-avfilter"

    # Use this to set your own configure-options
    if [ -f $SCRIPT_DIR/ffmpeg-conf ]
    then
        . $SCRIPT_DIR/ffmpeg-conf
    fi

    # Add x264 if exists
    if [ -f "$DIST_DIR/lib/libx264.a" ]; then
        CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --enable-libx264"
    fi

    # Add xvid if exists
    if [ -f "$DIST_DIR/lib/libxvid.a" ]; then
        CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --enable-libxvid"
    fi

    # Add vorbis if exists
    if [ -f "$DIST_DIR/lib/libvorbis.a" ]; then
        CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --enable-libvorbis"
    fi

    # Add vpx if exists
    if [ -f "$DIST_DIR/lib/libvpx.a" ]; then
        CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --enable-libvpx"
    fi

    # Add lame if exists
    if [ -f "$DIST_DIR/lib/libmp3lame.a" ]; then
        CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --enable-libmp3lame"
    fi

    # Add speex if exists
    if [ -f "$DIST_DIR/lib/libspeex.a" ]; then
        CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --enable-libspeex"
    fi


    # Use this to set your own build paths
    if [ -f $SCRIPT_DIR/build-local ]
    then
        . $SCRIPT_DIR/build-local
    fi

    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --extra-ldflags=-L$DIST_DIR/lib --extra-cflags=-I$DIST_DIR/include"

    case $ARCH in
        armv6)
            EXTRA_FLAGS="--enable-cross-compile --target-os=darwin --arch=arm --cpu=arm1176jzf-s"
            EXTRA_CFLAGS="-arch $ARCH -isysroot $SDKROOT"
            EXTRA_LDFLAGS="-arch $ARCH -isysroot $SDKROOT"
            ;;
        armv7)
            EXTRA_FLAGS="--enable-cross-compile --target-os=darwin --arch=arm --cpu=cortex-a8 --enable-pic"
            EXTRA_CFLAGS="-arch $ARCH -isysroot $SDKROOT"
            EXTRA_LDFLAGS="-arch $ARCH -isysroot $SDKROOT"
            ;;
    esac

    echo "Configure options: $CONFIGURE_OPTIONS"

    echo "Configuring ffmpeg for $ARCH..."
    ./configure --cc="$CC" --disable-bzlib --as="$SCRIPT_DIR/gas-preprocessor.pl $AS" --nm="$NM" --sysroot=$SDKROOT $EXTRA_FLAGS --extra-ldflags="$EXTRA_LDFLAGS" --extra-cflags="$EXTRA_CFLAGS" --prefix=$DIST_DIR $CONFIGURE_OPTIONS

    echo "Installing ffmpeg for $ARCH..."
    make && make install

    cd $SCRIPT_DIR

    rm -rf $DIST_DIR/bin
    rm -rf $DIST_DIR/share
done
