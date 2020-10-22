#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host

PRODUCT_BINARIES=swiftfsm swiftfsm-run swiftfsm-show swiftfsm-build swiftfsm-verify swiftfsm-update swiftfsm-add swiftfsm-init swiftfsm-remove

.ifndef TARGET
install: host
.else
install: cross
.endif
.for bin in ${PRODUCT_BINARIES}
	if [ -d ${BUILDDIR}/${bin:Q} ]; then \
		cp -pR ${BUILDDIR}/${bin:Q} ${DST:Q}/bin;\
	else \
		install -m 755 ${BUILDDIR}/${bin} ${DST:Q}/bin;\
	fi
.endfor

.ifdef TARGET
cross-install: install
.else
cross-install: cross
.  for rarch in ${ARCHS.${DEFAULT_TARGET}}
	$Eenv PATH=${TARGET_PATH.${DEFAULT_TARGET}:Q}                   \
		${MAKE} ${MAKEFLAGS} TARGET=${DEFAULT_TARGET}           \
		BUILD_FLAGS=${TARGET_BUILD_FLAGS.${DEFAULT_TARGET}:Q}   \
		TARGET_PLATFORM=${rarch} ALL_TARGETS=cross-install
.  endfor
.endif

.include "../../../mk/mipal.mk"
