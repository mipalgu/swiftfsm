#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=build-module
CI_WIP=yes
IN_FSM=yes

SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=FSM-Bridging-Header.h

LDFLAGS+=-lFunctional

.include "../../../mk/whiteboard.mk"    # I need the C whiteboard
.include "../swiftfsm.mk"
.include "../../../mk/mipal.mk"
