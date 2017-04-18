#!/bin/bash

# Sets the target folders and the final framework product.
FMK_NAME=libRTMP_iOS
FMK_VERSION=A

# Working dir will be deleted after the framework creation.
WRK_DIR=../tmp-build
DEVICE_DIR=${WRK_DIR}/Build/Products/Release-iphoneos/${FMK_NAME}.framework
DEVICE_DYSM=${DEVICE_DIR}.dSYM
SIMULATOR_DIR=${WRK_DIR}/Build/Products/Release-iphonesimulator/${FMK_NAME}.framework
SIMULATOR_DYSM=${SIMULATOR_DIR}.dSYM

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
INSTALL_DIR=${WRK_DIR}/../Products
INSTALL_FMK=${INSTALL_DIR}/${FMK_NAME}.framework
INSTALL_BIN=${INSTALL_FMK}/${FMK_NAME}
INSTALL_DSYM_DIR=${INSTALL_DIR}/dSYM

# Platform specific project
PLATFORM_PROJECT_DIR=${WRK_DIR}/../platform
PLATFORM_PROJECT_NAME=libRTMP.xcodeproj

#prepare Working directory
mkdir -p "${WRK_DIR}"

# Cleaning the previously built framework
if [ -d "${INSTALL_FMK}" ]
then
rm -rf "${INSTALL_FMK}"
fi

# Cleaning the previously stored iphoneos dsyms
if [ -d "${INSTALL_DSYM_DIR}/iphoneos" ]
then
rm -rf "${INSTALL_DSYM_DIR}/iphoneos"
fi

# Cleaning the previously stored iphonesimulator dsyms
if [ -d "${INSTALL_DSYM_DIR}/iphonesimulator" ]
then
rm -rf "${INSTALL_DSYM_DIR}/iphonesimulator"
fi

# Building both architectures.
xcodebuild -configuration "Release" -project "${PLATFORM_PROJECT_DIR}/${PLATFORM_PROJECT_NAME}" -scheme "${FMK_NAME}" -sdk iphoneos OTHERCFLAGS="-fembed-bitcode" ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode ARCHS="arm64 armv7" -derivedDataPath ${WRK_DIR}
if [ $? -ne 0 ]; then
        echo "Error - Build for iphoneos failed"
        exit 1
    fi 

xcodebuild -configuration "Release" -project "${PLATFORM_PROJECT_DIR}/${PLATFORM_PROJECT_NAME}" -scheme "${FMK_NAME}" -sdk iphonesimulator OTHERCFLAGS="-fembed-bitcode" ONLY_ACTIVE_ARCH=NO BITCODE_GENERATION_MODE=bitcode ARCHS="i386 x86_64"  -derivedDataPath ${WRK_DIR}

if [ $? -ne 0 ]; then
        echo "Error - Build for iphonesimulator failed"
        exit 1
    fi

# Prepare the final product
mkdir -p "${INSTALL_DIR}"
cp -Rp "${DEVICE_DIR}" "${INSTALL_DIR}/"

# Copy dSYM files
mkdir -p "${INSTALL_DSYM_DIR}/iphoneos"
mkdir -p "${INSTALL_DSYM_DIR}/iphonesimulator"

cp -Rp "${DEVICE_DYSM}" "${INSTALL_DSYM_DIR}/iphoneos/"
cp -Rp "${SIMULATOR_DYSM}" "${INSTALL_DSYM_DIR}/iphonesimulator/"

# Remove the binary, as it is about to be replaced by the Lippo'ed version
rm "${INSTALL_BIN}"

# Uses the Lipo Tool to merge both binary files (i386 + x86_64/armv7 + arm64) into one Universal final product.
lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${INSTALL_BIN}"
if [ $? -ne 0 ]; then
        	echo "Error - lipo failed"
        	exit 1
        fi
        
        echo " "
        echo "Fat-Mach-O details"
        otool -vf "${INSTALL_BIN}"
        echo " "
    
echo "Done"
# Delete build folder
echo "Cleaning up"
rm -r "${WRK_DIR}"

