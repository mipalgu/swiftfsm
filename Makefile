#
#	$Id$
#
# GU localisation module Makefile
#
ALL_TARGETS=host
CI_WIP=yes

#XCTSCHEME=swiftfsm_local
#XCODEPROJ=../swiftfsm.xcodeproj

SWIFT_BRIDGING_HEADER=swiftfsm-Bridging-Header.h

SWIFT_SRCS!=ls *.swift

#test:
#	xcodebuild -scheme ${XCTSCHEME} -project ${XCODEPROJ} -configuration Debug clean build test

.include "../../../mk/mipal.mk"
