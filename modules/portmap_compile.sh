logicTrue $(profile_get_key internal-uclibc) && require gcc

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/portmap_${PORTMAP_VER}.tar.gz"

portmap_compile::()
{
	local PORTMAP_SRCTAR="${SRCPKG_DIR}/portmap_${PORTMAP_VER}.tar.gz" PORTMAP_DIR="portmap_${PORTMAP_VER}"
	[ -f "${PORTMAP_SRCTAR}" ] || die "Could not find portmap source tarball: ${PORTMAP_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${PORTMAP_DIR}"
	unpack "${PORTMAP_SRCTAR}" || die "Failed to unpack portmap sources!"
	[ ! -d "${PORTMAP_DIR}" ] && die "portmap directory ${PORTMAP_DIR} invalid"

	cd "${PORTMAP_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/portmap/${PORTMAP_VER} .
	ARGS="O=-static"
	
    # turn on/off the cross compiler
	if [ -n "$(profile_get_key utils-cross-compile)" ]
	then
        TARGET=$(profile_get_key utils-cross-compile)
		ARGS="${ARGS} CC=$(profile_get_key utils-cross-compile)-gcc"
    else
        TARGET=$(gcc -dumpmachine)
	fi

	print_info 1 'portmap: >> Compiling...'
	
	compile_generic ${ARGS} # Compile
	#compile_generic ${ARGS} install

	
	[ -e "${TEMP}/portmap-compile" ] && rm -r ${TEMP}/portmap-compile
    mkdir -p ${TEMP}/portmap-compile/sbin

    cp portmap ${TEMP}/portmap-compile/sbin
    cp pmap_dump ${TEMP}/portmap-compile/sbin
    cp pmap_set ${TEMP}/portmap-compile/sbin
    cd ${TEMP}/portmap-compile

	${TARGET}-strip "${TEMP}/portmap-compile/sbin/portmap" || die 'Could not strip portmap binary!'
	${TARGET}-strip "${TEMP}/portmap-compile/sbin/pmap_dump" || die 'Could not strip pmap_dump binary!'
	${TARGET}-strip "${TEMP}/portmap-compile/sbin/pmap_set" || die 'Could not strip pmap_set binary!'
    genkernel_generate_package "portmap-${PORTMAP_VER}" "."
	
	cd ${TEMP}

	rm -rf "${PORTMAP_DIR}" > /dev/null
	rm -rf "${TEMP}/portmap-compile" > /dev/null
}
