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

.ifdef TARGET
FSM_INCLUDE_DIR?=${STAGING.${TARGET}}/usr/local/include/swiftfsm
FSM_LIB_DIR?=${STAGING.${TARGET}}/usr/local/lib
.endif

.include "../../../mk/prefs.mk"

.ifdef FSM_INCLUDE_DIR
SWIFTCFLAGS+=-I${FSM_INCLUDE_DIR}
.endif

.ifdef FSM_LIB_DIR
SWIFTCFLAGS+=-L${FSM_LIB_DIR}
.endif

.ifdef FSM_INCLUDE_DIR
CFLAGS+=-I${FSM_INCLUDE_DIR}
SWIFTCFLAGS+=-I${FSM_INCLUDE_DIR}
.endif

.ifdef FSM_LIB_DIR
LDFLAGS+=-L${FSM_LIB_DIR}
.endif

.ifdef WHITEBOARD_INCLUDE_DIR
CFLAGS+=-I${WHITEBOARD_INCLUDE_DIR} -I${WHITEBOARD_INCLUDE_DIR}/..
.endif

.ifdef WHITEBOARD_LIB_DIR
LDFLAGS+=-L${WHITEBOARD_LIB_DIR}
.endif

.ifdef CLREFLECT_INCLUDE_DIR
CFLAGS+=-I${CLREFLECT_INCLUDE_DIR}
.endif

.ifdef CLREFLECT_LIB_DIR
CFLAGS+=-L${CLREFLECT_LIB_DIR}
LDFLAGS+=-L${CLREFLECT_LIB_DIR}
.endif

CFLAGS+=-I${GUNAO_DIR}/Common
LDFLAGS+=-lgusimplewhiteboard -lFSM -ldl -lCLReflect -lgu_util

.ifdef NO_FOUNDATION
SWIFTCFLAGS+=-DNO_FOUNDATION
.endif

all:	all-real

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
