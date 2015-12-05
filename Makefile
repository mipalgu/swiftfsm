#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes

all:	all-real

host:	pre-build

SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h

HDRS=
HDRS+=invoke_func


SWIFT_SRCS!=ls *.swift
#C_SRCS!=ls *.c
SWIFTCFLAGS=-Xlinker all_load -Xlinker FSM.a -I./

pre-build:
	cd ../FSM && make
	mkdir -p build.host
	cp ../FSM/build.host-local/*.a ./build.host/
	cp ../FSM/build.host-local/*.dylib ./build.host/
	cp ../FSM/build.host-local/*.swift* ./build.host/

.include "../../../mk/mipal.mk"
