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
C_SRCSS!=ls *.c
SWIFTCFLAGS=-Xlinker all_load -lFSM -L./ -I./
LDFLAGS=-I./${BUILDDIR} -lFSM -L./${BUILDDIR}

pre-build:
	cd ../FSM && make
	mkdir -p build.host
	cp ../FSM/build.host-local/*.dylib ./build.host/
	cp ../FSM/build.host-local/*.swift* ./build.host/
.for src in ${C_SRCSS}
	$Eenv ${BUILD_ENV} ${CC} ${CFLAGS} ${LANGFL} ${CCWFLAGS} -c -o ${BUILDDIR}/`basename -s .c ${src}`.o ${src}
.endfor

post-build:
	cd build.host && mkdir -p build.host-local
	cd build.host/build.host-local && ln -f -s ../libFSM.dylib ./

.include "../../../mk/mipal.mk"

.for src in ${C_SRCSS}
        SWIFT_OBJS+=${BUILDDIR}/${src:.c=.o}
.endfor
OBJS=${SWIFT_OBJS}
