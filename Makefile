#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host-local

.ifdef SYSROOT
export LANG=/usr/lib/locale/en_US
.endif

.if ${OS} == Darwin
EXT=dylib
.else
EXT=so
.endif

INSTALL_DIR?=${SYSROOT}/usr/local/include/swiftfsm

.ifdef FSM_INCLUDE_DIR
SWIFTCFLAGS+=-I${FSM_INCLUDE_DIR}
.endif

.ifdef FSM_LIB_DIR
SWIFTCFLAGS+=-L${FSM_LIB_DIR}
.endif

.ifdef SYSROOT
FSM_INCLUDE_DIR?=${SYSROOT}/usr/local/include/swiftfsm
FSM_LIB_DIR?=${SYSROOT}usr/local/lib
SWIFT_BUILD_FLAGS=--destination destination.json
.endif

all:	all-real

install:
	mkdir -p ${SYSROOT}/usr/local/include/swiftfsm
	cp .build/${SWIFT_BUILD_CONFIG}/lib*.${EXT} ${SYSROOT}/usr/local/lib
	cp .build/${SWIFT_BUILD_CONFIG}/swiftfsm ${SYSROOT}/usr/local/bin/

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

.ifdef FSM_INCLUDE_DIR
CFLAGS+=-I${FSM_INCLUDE_DIR}
SWIFTCFLAGS+=-I${FSM_INCLUDE_DIR}
.else
CFLAGS+=-I${SYSROOT}/usr/local/include/swiftfsm
SWIFTCFLAGS+=-I${SYSROOT}/usr/local/include -I${SYSROOT}/usr/local/include/swiftfsm
.endif

.ifdef FSM_LIB_DIR
LDFLAGS+=-L${FSM_LIB_DIR}
.else
LDFLAGS+=-L${SYSROOT}/usr/local/lib
.endif

CFLAGS+=-I${SYSROOT}/usr/local/include -I${SYSROOT}/usr/local/include/gusimplewhiteboard -I${SYSROOT}/usr/local/include/CLReflect -I${GUNAO_DIR}/Common
LDFLAGS+=-lgusimplewhiteboard -lFSM -ldl -lCLReflect -lgu_util

.ifdef NO_FOUNDATION
SWIFTCFLAGS+=-DNO_FOUNDATION
.endif

.ifdef SYSROOT
LDFLAGS+=-L${SYSROOT}/lib -L${SYSROOT}/lib/swift/linux-fuse-ld=/home/user/src/swift-tc/ctc-linux64-atom-2.5.2.74/bin/i686-aldebaran-linux-gnu-ld 
.endif
