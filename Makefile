#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host

.if ${OS} == Darwin
EXT=dylib
.else
EXT=so
.endif

.ifdef TARGET
FSM_INCLUDE_DIR?=${STAGING.${TARGET}}/usr/local/include/swiftfsm
FSM_LIB_DIR?=${STAGING.${TARGET}}/usr/local/lib
.else
FSM_INCLUDE_DIR?=/usr/local/include/swiftfsm
FSM_LIB_DIR?=/usr/local/lib
.endif

PACKAGE_SWIFT?=${MODULE_DIR}/Package.in.swift

.include "../../../mk/prefs.mk"

NO_FOUNDATION_FILE?=.no-foundation

.if exists(${PWD}/${NO_FOUNDATION_FILE})
NO_FOUNDATION?=yes
.endif

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

.if defined(TARGET) || defined(NO_FOUNDATION)
SWIFTCFLAGS+=-DNO_FOUNDATION
.endif

all:	all-real

.ifdef TARGET
pre-build:	disable-foundation
.else
pre-build:	enable-foundation
.endif

generate-xcodeproj:
	$Ecp config.sh.in config.sh
	$Eecho "CCFLAGS=\"${CFLAGS:C,(.*),-Xcc \1,g}\"" >> config.sh
	$Eecho "LINKFLAGS=\"${LDFLAGS:C,(.*),-Xlinker \1,g}\"" >> config.sh
	$Eecho "SWIFTCFLAGS=\"${SWIFTCFLAGS:C,(.*),-Xswiftc \1,g}\"" >> config.sh
	$E./xcodegen.sh

.if exists(${NO_FOUNDATION_FILE}) || !exists(Package.swift)
enable-foundation:
	$E${MAKE} clean
	$Emkdir -p ${BUILDDIR}
	$Ecat Package.start.swift > Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.foundation.swift >> Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.in.swift >> Package.swift
	$Erm -f ${NO_FOUNDATION_FILE}
.else
enable-foundation:
.endif

.if !exists(${NO_FOUNDATION_FILE}) || !exists(Package.swift)
disable-foundation:
	$E${MAKE} clean
	$Emkdir -p ${BUILDDIR}
	$Ecat Package.start.swift > Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.slim.swift >> Package.swift
	$Eecho "" >> Package.swift
	$Ecat Package.in.swift >> Package.swift
	$Etouch ${NO_FOUNDATION_FILE}
.else
disable-foundation:
.endif

test:	swift-test-package

.include "../../../mk/mipal.mk"
