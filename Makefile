#
#	$Id$
#
# Global Makefile
#

ALL_TARGETS=host

PRODUCT_BINARIES=swiftfsm swiftfsm-run swiftfsm-show swiftfsm-build swiftfsm-verify swiftfsm-update

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

.include "../../../mk/mipal.mk"
