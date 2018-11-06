#!/bin/bash
#
ID=au.edu.griffith.ict.mipal
modver=1.0
ver=3.0
Mod=`grep name: Package.swift | head -n1 | cut -d'"' -f2`
Module=${Mod}-$ver
mod=`echo "${Mod}" | tr '[:upper:]' '[:lower:]'`+
module="${mod}-${modver}"
EXECUTABLE_NAME=${Mod}
PRODUCT_NAME=${Mod}
FULL_PRODUCT_NAME=${Mod}.app
PRODUCT_BUNDLE_IDENTIFIER=${ID}.${Mod}
MACOSX_DEPLOYMENT_TARGET=10.11
RESOURCES_DIR=`pwd`/Resources
BUILD_DIR=`pwd`/.build
BUILD_BIN=${BUILD_DIR}/debug
BUILT_PRODUCTS_DIR=${BUILD_DIR}/app
LINKFLAGS="-Xlinker -L/usr/local/lib -Xlinker -lFSM -Xlinker -lCLReflect"
CCFLAGS="-Xcc -I/usr/local/include -Xcc -I/usr/local/include/swiftfsm -Xcc -I/usr/local/include/CLReflect"
SWIFTCFLAGS="-Xswiftc -I/usr/local/include/swiftfsm"
