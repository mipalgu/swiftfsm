#
#	$Id$
#
# make file wrapper for gnumake
#
bmake=$(shell which nbmake bmake bsdmake pmake freebsd-make 2>/dev/null | head -n 1)
E?=@
PARALLEL?=-j4

all:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS}

clean:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} $@

host:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} $@

host-local:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} PARALLEL=${PARALLEL} $@

robot:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} $@

robot-local:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} PARALLEL=${PARALLEL} $@

local:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} $@

install:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} $@

install-local:
	$E${bmake} ${PARALLEL} ${MAKEFLAGS} PARALLEL=${PARALLEL} $@

echo:
	$Eecho "${bmake} ${PARALLEL} ${MAKEFLAGS} $@"

%:
	$E${bmake} ${MAKEFLAGS} $@
