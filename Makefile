#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes

DEPDIRS=../FSM
DEPLIBS=FSM

.ifndef TEST
# host source files and build settings
SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h
C_SRCSS!=ls *.c
SWIFTCFLAGS=-Xlinker all_load -lFSM -L./ -I./
.else
# test source files and build settings
BIN=swiftfsm_tests
SWIFT_SRCS!=grep -L "main" *.swift && ls tests/*.swift
SWIFT_BRIDGING_HEADER=tests/swiftfsm_tests-Bridging-Header.h
C_SRCSS!=ls *.c && ls tests/*.c
SWIFTCFLAGS=-Xlinker all_load -lFSM -L./ -I./ -lswiftXCTest
.endif
LDFLAGS=-I./${BUILDDIR} -lFSM -L./${BUILDDIR}

.include "../swiftfsm.mk"
