#!/bin/bash

# Sets the target folders and the final framework product.
FMK_NAME=dylibRTMP_macOS
FMK_VERSION=A

# Working dir will be deleted after the framework creation.
WRK_DIR=../tmp-build
DEVICE_DIR=${WRK_DIR}/Build/Products/Release/${FMK_NAME}.framework
DEVICE_DYSM=${DEVICE_DIR}.dSYM

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
INSTALL_DIR=../Products
INSTALL_FMK=${INSTALL_DIR}/${FMK_NAME}.framework
INSTALL_BIN=${INSTALL_FMK}/${FMK_NAME}
INSTALL_DSYM_DIR=${INSTALL_DIR}/dSYM

# Platform specific project
PLATFORM_PROJECT_DIR=${WRK_DIR}/../platform/libRTMP
PLATFORM_PROJECT_NAME=libRTMP.xcodeproj

#prepare Working directory
mkdir -p "${WRK_DIR}"

# Cleaning the previously built framework
if [ -d "${INSTALL_FMK}" ]
then
rm -rf "${INSTALL_FMK}"
fi

# Cleaning the previously stored dsyms
if [ -d "${INSTALL_DSYM_DIR}/macOS" ]
then
rm -rf "${INSTALL_DSYM_DIR}/macOS"
fi

# Build

xcodebuild -configuration Release -project "${PLATFORM_PROJECT_DIR}/${PLATFORM_PROJECT_NAME}" -scheme "${FMK_NAME}" -sdk macosx ONLY_ACTIVE_ARCH=NO -derivedDataPath ${WRK_DIR}

if [ $? -ne 0 ]; then
        echo "Error - Build for macOS failed"
        exit 1
    fi 
    
# Prepare the final product
mkdir -p "${INSTALL_DIR}"
cp -Rp "${DEVICE_DIR}" "${INSTALL_DIR}/"

# Copy dSYM files
mkdir -p "${INSTALL_DSYM_DIR}/macOS"

cp -Rp "${DEVICE_DYSM}" "${INSTALL_DSYM_DIR}/macOS/"

# Print binary header
otool -hv "${INSTALL_BIN}" 

echo "Done"
# Delete build folder
echo "Cleaning up"
rm -r "${WRK_DIR}"

