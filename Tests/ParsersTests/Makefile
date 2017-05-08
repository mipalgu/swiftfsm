#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes
BIN=Parser_tests
TESTFILE=1
USE_FSM=yes

all:	all-real

SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=Parser_tests-Bridging-Header.h
ALL_HDRS!=ls *.h
LDFLAGS+=-lParsers -lFunctional -lIO

.include "../../swiftfsm.mk"
.include "../../../../mk/mipal.mk"
