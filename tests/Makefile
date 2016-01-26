#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes
BIN=swiftfsm_tests
TESTFILE=1

B_D=./build.host
DEPDIRS=../
DEPLIBS=swiftfsm

ALL_HDRS!=ls *.h
HOST_SWIFTC=swiftc
C_FLAGS=-lrt -ldl 
SWIFTCFLAGS=-Xlinker all_load -lFSM -lswiftfsm -ldl -L./ -I${SRCDIR}/../ -I${SRCDIR} -I${SRCDIR}/../../.. -I${SRCDIR}/../../../../Common
SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=swiftfsm_tests-Bridging-Header.h
C_SRCS!=ls *.c
LDFLAGS=-lFSM -lswiftfsm

all:	all-real

pre-build:	generate-class
	cd ../ && bmake host-local TESTING=TESTING	

.include "../../swiftfsm.mk"
.include "../../../../mk/mipal.mk"
