logicTrue $(profile_get_key internal-uclibc) && require gcc
require device_mapper

# Check that these files exist if we are compiling lvm2"
files_register "${SRCPKG_DIR}/LVM2.${LVM2_VER}.tgz"

lvm2_compile::() {
	local LVM2_DIR="LVM2.${LVM2_VER}" LVM2_SRCTAR="${SRCPKG_DIR}/LVM2.${LVM2_VER}.tgz"
	[ -f "${LVM2_SRCTAR}" ] || die "Could not find LVM2 source tarball: ${LVM2_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${TEMP}/${LVM2_DIR}"
	unpack "${LVM2_SRCTAR}" || die "Failed to unpack LVM2 sources!"
	[ -d "${LVM2_DIR}" ] || die "LVM2 directory ${LVM2_DIR} invalid!"

	cd "${LVM2_DIR}"
	print_info 1 'LVM2: >> Configuring...'
	cp /usr/share/gnuconfig/* autoconf

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
	ac_cv_func_malloc_0_nonnull=yes \
	configure_generic ${ARGS} --enable-static_link --prefix=${TEMP}/LVM2  --with-confdir=${TEMP}/LVM2/etc

	mkdir -p "${TEMP}/LVM2/sbin"
	print_info 1 'LVM2: >> Compiling...'
	
	CC=${TARGET}-gcc \
	CXX=${TARGET}-g++ \
	LDFLAGS="-L${DEVICE_MAPPER}/lib" \
	CFLAGS="-I${DEVICE_MAPPER}/include" \
	CPPFLAGS="-I${DEVICE_MAPPER}/include" \
	ac_cv_func_malloc_0_nonnull=yes \
	compile_generic # Compile
	#compile_generic install
    cp tools/lvm.static ${TEMP}/LVM2/sbin
	cd "${TEMP}/LVM2"
	chmod u+w sbin/lvm.static # Fix crazy permissions to strip
	${TARGET}-strip sbin/lvm.static || die 'Could not strip lvm.static!'
	genkernel_generate_package "lvm2-${LVM2_VER}" sbin/lvm.static || die 'Could not create LVM2 package!'

	cd "${TEMP}"
	rm -rf "${TEMP}/LVM2" "${TEMP}/${LVM2_DIR}"
}
