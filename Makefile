#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host-local

.if ${OS} == Darwin
EXT=dylib
.else
EXT=so
.endif

SWIFTCFLAGS+=-I/usr/local/include/swiftfsm

all:	all-real

install:
	mkdir -p /usr/local/include/swiftfsm
	${E}cp .build/${SWIFT_BUILD_CONFIG}/lib*.${EXT} /usr/local/lib
	${E}cp .build/${SWIFT_BUILD_CONFIG}/*.swift* /usr/local/include/swiftfsm
	${E}cp .build/${SWIFT_BUILD_CONFIG}/swiftfsm /usr/local/bin/

test:	swift-test-package

.include "../../../mk/mipal.mk"

CFLAGS+=-I/usr/local/include -I/usr/local/include/swiftfsm -I${GUNAO_DIR}/Common

LDFLAGS+=-L/usr/local/lib/swiftfsm -lFSM
