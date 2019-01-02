#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host-local

.ifdef SYSROOT
export LANG=/usr/lib/locale/en_US
ROOT=${SYSROOT}
.else
ROOT=
.endif

.if ${OS} == Darwin
EXT=dylib
.else
EXT=so
.endif

SWIFTCFLAGS+=-I${ROOT}/usr/local/include/swiftfsm
.ifdef SYSROOT
SWIFT_BUILD_FLAGS=--destination destination.json
.endif

all:	all-real

install:
	mkdir -p ${ROOT}/usr/local/include/swiftfsm
	cp .build/${SWIFT_BUILD_CONFIG}/lib*.${EXT} ${ROOT}/usr/local/lib
	cp .build/${SWIFT_BUILD_CONFIG}/*.swift* ${ROOT}/usr/local/include/swiftfsm
	cp .build/${SWIFT_BUILD_CONFIG}/swiftfsm ${ROOT}/usr/local/bin/

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

CFLAGS+=-I${ROOT}/usr/local/include -I${ROOT}/usr/local/include/gusimplewhiteboard -I${ROOT}/usr/local/include/swiftfsm -I${ROOT}/usr/local/include/CLReflect -I${GUNAO_DIR}/Common
SWIFTCFLAGS=-I${ROOT}/usr/local/include -I${ROOT}/usr/local/include/swiftfsm
.ifdef NO_FOUNDATION
SWIFTCFLAGS+=-DNO_FOUNDATION
.endif
LDFLAGS+=-L${ROOT}/usr/local/lib -lgusimplewhiteboard -lFSM -ldl -lCLReflect -lgu_util

.ifdef SYSROOT
LDFLAGS+=-L${ROOT}/lib -L${ROOT}/lib/swift/linux-fuse-ld=/home/user/src/swift-tc/ctc-linux64-atom-2.5.2.74/bin/i686-aldebaran-linux-gnu-ld 
.endif
