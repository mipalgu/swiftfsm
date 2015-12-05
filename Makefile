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

SWIFT_SRCS!=ls *.swift
#C_SRCS!=ls *.c
#C_HDRS!=ls *.h
SWIFTCFLAGS=-Xlinker all_load -Xlinker FSM.a -I./ -F./ -L./

pre-build:
	cd ../FSM && make
	mkdir -p build.host
	cp ../FSM/build.host-local/*.a ./build.host/
	cp ../FSM/build.host-local/*.dylib ./build.host/
	cp ../FSM/build.host-local/*.swift* ./build.host/

.include "../../../mk/mipal.mk"
