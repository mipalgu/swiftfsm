#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes
all:	all-real

ALL_HDRS!=ls *.h
HOST_SWIFTC=swiftc
.if ${OS} == Linux 
SPECIFIC_CFLAGS=-D_POSIX_C_SOURCE=199309L
.endif
CFLAGS=-lrt -ldl -D_POSIX_C_SOURCE=199309L 
SWIFTCFLAGS=-Xlinker all_load -lFSM -ldl -L./ -I./ -I${SRCDIR}/../.. -I${SRCDIR}/../../../Common
SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h
C_SRCS!=ls *.c
LDFLAGS=-lFSM

.include "../swiftfsm.mk"
.include "../../../mk/mipal.mk"
