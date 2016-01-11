#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes

DEPDIRS=../FSM
DEPLIBS=FSM

HOST_SWIFTC=swiftc
CC=gcc
.ifndef TEST
# host source files and build settings
SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h
C_SRCSS!=ls *.c
C_FLAGS=-lrt -ldl 
SWIFTCFLAGS=-Xlinker all_load -lFSM -ldl -L./ -I./ -I${SRCDIR}/../.. -I${SRCDIR}/../../../Common
.else
# test source files and build settings
BIN=swiftfsm_tests
SWIFT_SRCS!=grep -L "main" *.swift && ls tests/*.swift
SWIFT_BRIDGING_HEADER=tests/swiftfsm_tests-Bridging-Header.h
C_SRCSS!=ls *.c && ls tests/*.c
C_FLAGS=-lrt
SWIFTCFLAGS=-Xlinker all_load -lFSM -L./ -I./ -I${SRCDIR}/../.. -I${SRCDIR}/../../../Common -lswiftXCTest
.endif
LDFLAGS=-I./${BUILDDIR} -lFSM -L./${BUILDDIR}

#test:	test-executable

.include "../swiftfsm.mk"
.include "../../../mk/mipal.mk"
