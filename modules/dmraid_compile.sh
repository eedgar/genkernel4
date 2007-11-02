logicTrue $(profile_get_key internal-uclibc) && require gcc
require device_mapper

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/dmraid-${DMRAID_VER}.tar.bz2"

dmraid_compile::() {
	local DMRAID_DIR="dmraid/${DMRAID_VER}" DMRAID_SRCTAR="${SRCPKG_DIR}/dmraid-${DMRAID_VER}.tar.bz2"
	local ARGS
	[ -f "${DMRAID_SRCTAR}" ] || die "Could not find dmraid source tarball: ${DMRAID_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${TEMP}/${DMRAID_DIR}"
	unpack "${DMRAID_SRCTAR}" || die "Failed to unpack dmraid sources!"
	[ -d "${DMRAID_DIR}" ] || die "dmraid directory ${DMRAID_DIR} invalid!"

	cd "${DMRAID_DIR}"
	cp /usr/share/gnuconfig/* autoconf

	print_info 1 'dmraid: >> Configuring...'
	# turn on/off the cross compiler
	if [ -n "$(profile_get_key utils-cross-compile)" ]
	then
		TARGET=$(profile_get_key utils-cross-compile)
		ARGS="${ARGS} --host=$(${TARGET}-gcc -dumpmachine) --target=${TARGET}"
	else
		TARGET=$(gcc -dumpmachine)
	fi
	
	
	CC=${TARGET}-gcc \
	CXX=${TARGET}-g++ \
	LDFLAGS="-L${DEVICE_MAPPER}/lib" \
	CFLAGS="-I${DEVICE_MAPPER}/include" \
	CPPFLAGS="-I${DEVICE_MAPPER}/include" \
	configure_generic --enable-static_link --prefix=${TEMP}/dmraid ${ARGS}
	
	mkdir -p "${TEMP}/dmraid"
	sed -i tools/Makefile -e "s|DMRAIDLIBS += -lselinux||g"

	print_info 1 'dmraid: >> Compiling...'
	
	CC=${TARGET}-gcc \
	CXX=${TARGET}-g++ \
	LDFLAGS="-L${DEVICE_MAPPER}/lib" \
	CFLAGS="-I${DEVICE_MAPPER}/include" \
	CPPFLAGS="-I${DEVICE_MAPPER}/include" \
	compile_generic

	mkdir "${TEMP}/dmraid/sbin"
	install -m 0755 -s tools/dmraid "${TEMP}/dmraid/sbin/dmraid"

	cd "${TEMP}/dmraid"
	genkernel_generate_package "dmraid-${DMRAID_VER}" sbin/dmraid || die 'Could not create dmraid package!'\

	cd "${TEMP}"
	rm -rf "${TEMP}"/dmraid "${TEMP}/${DMRAID_DIR}"
}
