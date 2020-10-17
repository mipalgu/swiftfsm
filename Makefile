#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host

install:
	install .build/${SWIFT_BUILD_CONFIG}/swiftfsm        \
		.build/${SWIFT_BUILD_CONFIG}/swiftfsm-run    \
		.build/${SWIFT_BUILD_CONFIG}/swiftfsm-build  \
		.build/${SWIFT_BUILD_CONFIG}/swiftfsm-verify \
		.build/${SWIFT_BUILD_CONFIG}/swiftfsm-update \
		/usr/local/bin/

.include "../../../mk/mipal.mk"
