#!/bin/bash

##
## Creates a copy of the iOS framework, having the x86_64 and i386 slices removed
## You can use this binary for AppStore submissions which do not allow the removed slices

FMK_NAME=libRTMP_iOS
FMK_VERSION=A

PRODUCTS_DIR=../Products
FOR_STORE_BUILDS=${PRODUCTS_DIR}/AppStore

rm -rf ${FOR_STORE_BUILDS}
mkdir -p ${FOR_STORE_BUILDS}

FULL_FMK=${PRODUCTS_DIR}/${FMK_NAME}.framework
THIN_FMK=${FOR_STORE_BUILDS}/${FMK_NAME}.framework
THIN_FMK_BINARY=${THIN_FMK}/${FMK_NAME}


ditto -vV --arch arm64 --arch armv7  "${FULL_FMK}" "${THIN_FMK}"

if [ $? -ne 0 ]; then
        	echo "Error - ditto failed"
        	exit 1
        fi
        
        echo " "
        echo "Fat-Mach-O details"
        otool -vf "${THIN_FMK_BINARY}"
        echo " "
    
echo "Done"


