#!/bin/bash

## Doron Adler, GlideTalk, @Norod78

##
## Clone rtmpdump
echo "******************************************************"
echo "           Cloning rtmpdump from ffmpeg.org           "
echo "******************************************************"
git clone https://git.ffmpeg.org/rtmpdump.git
## Update HEAD
git checkout fa8646daeb19dfd12c181f7d19de708d623704c0
echo "Done"

##
## This script builds the iOS and Mac openSSL libraries with Bitcode enabled
## 
echo "******************************************************"
echo "           Download and build OpenSSL                 "
echo "******************************************************"
pushd ./OpenSSL/
./build-OpenSSL-iOS-Mac.sh
echo "Done"
popd


##
## This scripts builds iOS and Mac dynamic frameworks wrapping rtmpdump
## 
echo "******************************************************"
echo "           Build libRTMP                              "
echo "******************************************************"
pushd ./scripts
./build-macOS.sh
./build-iOS.sh
./strip-iOS-sim.sh
echo "Done"
popd

open ./platform/verifyLinkToLib
open ./Products

