#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes

.ifndef TEST
# host source files and build settings
SWIFT_SRCS!=ls *.swift
SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h
C_SRCSS!=ls *.c
SWIFTCFLAGS=-Xlinker all_load -lFSM -L./ -I./
.else
# test source files and build settings
SWIFT_SRCS!=grep -L "main" *.swift && ls tests/*.swift
SWIFT_BRIDGING_HEADER=tests/swiftfsm_tests-Bridging-Header.h
C_SRCSS!=ls *.c && ls tests/*.c
SWIFTCFLAGS=-Xlinker all_load -lFSM -L./ -I./ -lswiftXCTest
.endif
LDFLAGS=-I./${BUILDDIR} -lFSM -L./${BUILDDIR}

all:	all-real

host:	pre-build

test:
	make host TEST=TEST

pre-build:
	cd ../FSM && make
	mkdir -p build.host
	cp ../FSM/build.host-local/*.dylib ./build.host/  2>/dev/null || :
	cp ../FSM/build.host-local/*.so ./build.host/  2>/dev/null || :
	cp ../FSM/build.host-local/*.swift* ./build.host/
	ln -sf build.host ./build.host-local
.for src in ${C_SRCSS}
	mkdir -p ${BUILDDIR}/`dirname ${src}`
	$Eenv ${BUILD_ENV} ${CC} ${CFLAGS} ${LANGFL} ${CCWFLAGS} -c -o ${BUILDDIR}/`dirname ${src}`/`basename -s .c ${src}`.o ${src}
.endfor

post-build:
	cd build.host && mkdir -p build.host-local
	cd build.host/build.host-local && ln -f -s ../libFSM.dylib ./

.include "../../../mk/mipal.mk"

.for src in ${C_SRCSS}
        SWIFT_OBJS+=${BUILDDIR}/${src:.c=.o}
.endfor
OBJS=${SWIFT_OBJS}
