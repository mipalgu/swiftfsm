#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes

ALL_HDRS!=ls *.h

.if ${OS} == Linux 
SPECIFIC_CFLAGS=-D_POSIX_C_SOURCE=199309L
.endif

SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h
C_SRCS!=ls *.c
LDFLAGS+=-L/usr/local/lib -lIO -lFunctional

.include "../swiftfsm.mk"
.include "../../../mk/mipal.mk"
