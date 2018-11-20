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

all:	all-real

install:
	mkdir -p /usr/local/include/swiftfsm
	cp .build/${SWIFT_BUILD_CONFIG}/lib*.${EXT} /usr/local/lib
	cp .build/${SWIFT_BUILD_CONFIG}/*.swift* /usr/local/include/swiftfsm
	cp .build/${SWIFT_BUILD_CONFIG}/swiftfsm /usr/local/bin/

generate-xcodeproj:
	$Ecp config.sh.in config.sh
	$Eecho "CCFLAGS=\"${CFLAGS:C,(.*),-Xcc \1,g}\"" >> config.sh
	$Eecho "LINKFLAGS=\"${LDFLAGS:C,(.*),-Xlinker \1,g}\"" >> config.sh
	$Eecho "SWIFTCFLAGS=\"${SWIFTCFLAGS:C,(.*),-Xswiftc \1,g}\"" >> config.sh
	$E./xcodegen.sh

enable-foundation:
	$Ecat Package.start.swift > Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.foundation.swift >> Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.in.swift >> Package.swift

disable-foundation:
	$Ecat Package.start.swift > Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.slim.swift >> Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.in.swift >> Package.swift

test:	swift-test-package

.include "../../../mk/mipal.mk"

CFLAGS+=-I/usr/local/include -I/usr/local/include/gusimplewhiteboard -I/usr/local/include/swiftfsm -I/usr/local/include/CLReflect -I${GUNAO_DIR}/Common
SWIFTCFLAGS=-I/usr/local/include -I/usr/local/include/swiftfsm
.ifdef NO_FOUNDATION
SWIFTCFLAGS+=-DNO_FOUNDATION
.endif
LDFLAGS+=-L/usr/local/lib -L/usr/local/lib/swiftfsm -lFSM -lCLReflect -ldl
