#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes

ALL_HDRS!=ls *.h
HOST_SWIFTC=swiftc

.if ${OS} == Linux 
SPECIFIC_CFLAGS=-D_POSIX_C_SOURCE=199309L
.endif

SWIFTCFLAGS=-I${SRCDIR}/../.. -I${SRCDIR}/../../../Common
SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h
C_SRCS!=ls *.c

.include "../swiftfsm.mk"
.include "../../../mk/mipal.mk"
