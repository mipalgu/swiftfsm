#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host

PRODUCT_MODULES=swiftfsm ExternalVariables FSM Utilities
PRODUCT_LIBS=FSM CFSMS
PRODUCT_BINARIES=swiftfsm swiftfsm-run swiftfsm-show swiftfsm-build swiftfsm-verify swiftfsm-update swiftfsm-add swiftfsm-init swiftfsm-remove swiftfsm-clean

.ifndef TARGET
install: host
.else
install: cross
.endif
.ifdef PRODUCT_MODULES
	mkdir -p ${DST:Q}/include/${MODULE_BASE}
	-rm ${DST:Q}/include/${MODULE_BASE}/*
.for module in ${PRODUCT_MODULES}
	install -m 644 ${BUILDDIR}/${module}.swiftmodule ${DST:Q}/include/${MODULE_BASE}
	install -m 644 ${BUILDDIR}/${module}.swiftdoc ${DST:Q}/include/${MODULE_BASE}
	install -m 644 ${BUILDDIR}/${module}.swiftsourceinfo ${DST:Q}/include/${MODULE_BASE}
.endfor
.endif
.for lib in ${PRODUCT_LIBS}
	install -m 755 ${BUILDDIR}/${SOPREFIX}${lib}${SOEXT} ${DST:Q}/lib
.endfor
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
