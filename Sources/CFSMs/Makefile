#
#	$Id: 5804a543130cfb42b0ad795a0a8a28d4625fa6af $
#
# Makefile for libclfsm
#
#MODULE_BASE=clfsm
#XCTSCHEME=libclfsm
#CI_NAME=${XCTSCHEME}

ALL_TARGETS=host-local

#CATKIN_BASE=libclfsm
#CATKIN_COMPILE_UTIL=YES

#CATKIN_HDRS+=${MODULE_DIR}/../clfsm/CLReflect/CLReflectTypeEnum

#XCODE_USE_WORKSPACE=yes

.include "../../../../../mk/c++11.mk"	# use C++11

#CPPFLAGS+=-g -O0
SPECIFIC_LDFLAGS+=-Wl,-rpath -Wl,/usr/local/lib

#C_SRCS=stringConstants.c
CC_SRCS=cfsm_control.cc cfsm_current_time_in_microseconds.cc cfsm_index.cc cfsm_start_time_for_current_state.cc StateMachineVector.cc SuspensibleMachine.cc
HDRS=CLAction.h CLMachine.h CLMacros.h CLState.h CLTransitionExpression.h CLTransition.h StateMachineVector.h SuspensibleMachine.h
INSTHDRS=CLMacros.h #CLWhiteboard.h
LDFLAGS+=-lCLReflect


.include "../../../../../mk/whiteboard.mk"	# required for whiteboard clients
.include "../../../../../mk/util.mk"		# required for GU utility functions

#.for hdr in WBFunctor.h WBMsg.h
#CATKIN_HDRS+=${WB_DIR}/${hdr}
#.endfor

#CATKIN_HDRS+=${INSTHDRS}

#.if ${LOCAL} != _LOCAL
#host: host-local
#	echo "Use 'make host-local' instead of 'make host'"

#upload-robot:
#	mkdir -p -m 0755 ${DESTDIR}${PREFIX:Q}/include/clfsm
#	mkdir -p -m 0755 ${DESTDIR}${PREFIX:Q}/lib
#	[ ! -e /usr/bin/install_name_tool ] || \
#	  /usr/bin/install_name_tool -id ${PREFIX:Q}/lib/${OUTFILE_LOCAL:Q} ${BUILDDIR}-local/*${SOEXT}*
#	cd ${BUILDDIR}-local && \
#	install -m 0755 *${SOEXT}* ${DESTDIR}${PREFIX:Q}/lib
#.for hdr in ${INSTHDRS}
#	cd ${SRCDIR}/../clfsm && \
#	install -m 0644 ${hdr} /usr/local/include/clfsm
#.endfor
#.endif

#tests: host-local
#	$E${MAKE} -C libclfsmTests clean
#	$E${MAKE} -C libclfsmTests tests


.ifndef TARGET
install: host-local
.else
install: cross-local
.endif
	mkdir -p -m 0755 ${DST:Q}/include/clfsm
	-mkdir -p -m 0755 ${DST:Q}/lib
	cd ${BUILDDIR}-local && \
	install -m 0755 *${SOEXT}* ${DST:Q}/lib
.for hdr in ${INSTHDRS}
	cd ${SRCDIR} && \
	if [ -d ${hdr:Q} ]; then \
	  cp -pR ${hdr:Q} ${DST:Q}/include/clfsm;\
	else \
	  install -m 0644 ${hdr} ${DST:Q}/include/clfsm;\
	fi
.endfor


.ifdef TARGET
cross-install: install
.else
cross-install: cross-local
.  for rarch in ${ARCHS.${DEFAULT_TARGET}}
	$Eenv PATH=${TARGET_PATH.${DEFAULT_TARGET}:Q}                   \
                ${MAKE} ${MAKEFLAGS} TARGET=${DEFAULT_TARGET}           \
                BUILD_FLAGS=${TARGET_BUILD_FLAGS.${DEFAULT_TARGET}:Q}   \
                TARGET_PLATFORM=${rarch} ALL_TARGETS=cross-install
.  endfor
.endif


#pre-catkin:
#	$Emkdir -p ${CATKIN_DIR}/include/typeClassDefs
#.for hfile in FSM_Control.h FSMControlStatus.h wb_fsm_control_status.h wb_fsm_state_status.h
#	$Ecp -p ${WB_DIR}/typeClassDefs/${hfile} ${CATKIN_DIR}/include/typeClassDefs
#.endfor

test:
	$Eecho "libclfsm tests take a while to compile, so please run"
	$Eecho "	make tests"
	$Eecho "to run your tests manually!"

.include "../../../../../mk/mipal.mk"		# comes last!
