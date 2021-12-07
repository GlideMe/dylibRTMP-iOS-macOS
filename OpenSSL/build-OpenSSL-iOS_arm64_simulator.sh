#!/bin/bash

# This script builds the iOS and Mac openSSL libraries with Bitcode enabled
# Download openssl http://www.openssl.org/source/ and place the tarball next to this script

# Credits:
# https://github.com/st3fan/ios-openssl
# https://github.com/x2on/OpenSSL-for-iPhone/blob/master/build-libssl.sh
# Peter Steinberger, PSPDFKit GmbH, @steipete.
# Doron Adler, GlideTalk, @Norod78

# Updated to work with Xcode 8 and iOS 10
# Updated to build for only 64bit architectures

set -e

###################################
# 		 OpenSSL Version
###################################
OPENSSL_VERSION="openssl-1.1.1g"
###################################

###################################
# 		 SDK Version
###################################
IOS_SDK_VERSION=$(xcodebuild -version -sdk iphoneos | grep SDKVersion | cut -f2 -d ':' | tr -d '[[:space:]]')
###################################

################################################
# 		 Minimum iOS deployment target version
################################################
MIN_IOS_VERSION="13.0"

################################################
# 		 Minimum OS X deployment target version
################################################
MIN_OSX_VERSION="10.13"

echo "----------------------------------------"
echo "OpenSSL version: ${OPENSSL_VERSION}"
echo "iOS SDK version: ${IOS_SDK_VERSION}"
echo "iOS deployment target: ${MIN_IOS_VERSION}"
echo "OS X deployment target: ${MIN_OSX_VERSION}"
echo "----------------------------------------"
echo " "

DEVELOPER=`xcode-select -print-path`
buildMac()
{
	ARCH=$1
	echo "Start Building ${OPENSSL_VERSION} for ${ARCH}"
	TARGET="darwin64-arm64-cc"
	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
	fi
	
	export CC="${BUILD_TOOLS}/usr/bin/clang -mmacosx-version-min=${MIN_OSX_VERSION}"
	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"
	pwd
	mkdir -p "/tmp/${OPENSSL_VERSION}-${ARCH}/lib"
	echo "Configure"
	if [[ $ARCH == "x86_64" ]]; then
		./Configure ${TARGET} --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"
	else
		./Configure ${TARGET} no-asm --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"
	fi
	echo "make"
	make >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1	
	echo "move dylib"
	mv ./*.dylib "/tmp/${OPENSSL_VERSION}-${ARCH}/lib/"
	echo "move a"
	mv ./*.a "/tmp/${OPENSSL_VERSION}-${ARCH}/lib/"
	echo "copy include"
	cp -r ./include "/tmp/${OPENSSL_VERSION}-${ARCH}/include"
	echo "make clean"
	make clean >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	popd > /dev/null	
	
	echo "Done Building ${OPENSSL_VERSION} for ${ARCH}"
}
buildIOS()
{
	ARCH=$1
	PLATFORM=$2

	echo "Start Building ${OPENSSL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
	
	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	if [[ $PLATFORM == "iPhoneSimulator" ]]; then
		echo "iPhone Simulator"
	else
		PLATFORM="iPhoneOS"
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
		echo "iPhone Device"
	fi
  
	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH} -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK}"
	
	pwd
	echo "Configure"
	if [[ $ARCH == "x86_64" ]]; then
		./Configure darwin64-x86_64-cc "-mios-simulator-version-min=${MIN_IOS_VERSION}" no-asm no-shared no-hw no-async --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}.log"
	elif [[ $ARCH == "arm64" ]] && [[ $PLATFORM == "iPhoneSimulator" ]]; then 
		./Configure iossimulator-xcrun "-mios-simulator-version-min=${MIN_IOS_VERSION}" no-asm no-shared no-hw no-async --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}.log"
	else
		./Configure iphoneos-cross "-mios-version-min=${MIN_IOS_VERSION}" no-asm no-shared no-hw no-async --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}" &> "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}.log"
	fi
	# add -isysroot to CC=
	sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mios-version-min=${MIN_IOS_VERSION} !" "Makefile"
	echo "make"
	make >> "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}.log" 2>&1
	echo "move a"
	mkdir -p "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}/lib/"
	mv ./*.a "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}/lib/"
	echo "copy include"
	mkdir -p "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}/include/"
	cp -r ./include "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}/include"
	echo "make clean"
	make clean  >> "/tmp/${OPENSSL_VERSION}-iOS-${PLATFORM}-${ARCH}.log" 2>&1
	popd > /dev/null
	
	echo "Done Building ${OPENSSL_VERSION} for ${PLATFORM}-${ARCH}"
}
echo "Cleaning up"
rm -rf include/openssl/* lib/*
rm -rf /tmp/${OPENSSL_VERSION}-*
rm -rf ${OPENSSL_VERSION}
mkdir -p lib/iOS
mkdir -p lib/Mac
mkdir -p include/openssl/
rm -rf "/tmp/${OPENSSL_VERSION}-*"
rm -rf "/tmp/${OPENSSL_VERSION}-*.log"
rm -rf "${OPENSSL_VERSION}"
if [ ! -e ${OPENSSL_VERSION}.tar.gz ]; then
	echo "Downloading ${OPENSSL_VERSION}.tar.gz"
	curl -O https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
else
	echo "Using ${OPENSSL_VERSION}.tar.gz"
fi
echo "Unpacking openssl"
tar xfz "${OPENSSL_VERSION}.tar.gz"
#echo "Overwrite ${OPENSSL_VERSION}/Configurations/10-main.conf"
#cp ./10-main.conf.patch "${OPENSSL_VERSION}/Configurations/10-main.conf"
buildIOS "arm64" "iPhoneSimulator"
#buildIOS "arm64" "iPhoneOS"
buildIOS "x86_64" "iPhoneSimulator"
buildMac "arm64"
buildMac "x86_64"
echo "Copying headers"
cp /tmp/${OPENSSL_VERSION}-x86_64/include/openssl/* include/openssl/
echo "Building Mac libraries"
lipo \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-arm64/lib/libcrypto.a" \
	-create -output lib/Mac/libcrypto.a
lipo \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-arm64/lib/libssl.a" \
	-create -output lib/Mac/libssl.a
#echo "Cleaning up"
#rm -rf /tmp/${OPENSSL_VERSION}-*
#rm -rf ${OPENSSL_VERSION}
echo "Done"
