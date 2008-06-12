require kernel_headers uclibc_stage2

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/gcc-${GCC_VER}.tar.bz2"

gcc_stage2_compile::()
{
	local GCC_SRCTAR="${SRCPKG_DIR}/gcc-${GCC_VER}.tar.bz2" GCC_DIR="gcc-${GCC_VER}" 
	local GCC_BUILD_DIR="gcc-${GCC_VER}-build"
	[ -f "${GCC_SRCTAR}" ] || die "Could not find gcc source tarball: ${GCC_SRCTAR}!"

	cd "${CACHE_DIR}"
	rm -rf ${GCC_DIR} > /dev/null
	unpack ${GCC_SRCTAR} || die 'Could not extract gcc source tarball!'
	[ -d "${GCC_DIR}" ] || die 'gcc directory ${GCC_DIR} is invalid!'

	# Apply patches
	cd "${GCC_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/gcc/${GCC_VER} .

	cd "${CACHE_DIR}"
	[ -e "${GCC_BUILD_DIR}" ] && rm -rf "${GCC_BUILD_DIR}"
	mkdir -p "${GCC_BUILD_DIR}"
	cd "${GCC_BUILD_DIR}"

	print_info 1 'gcc: >> Configuring...'
	GCC_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
    -e 's/x86$/i386/' \
    -e 's/i.86$/i386/' \
    -e 's/sparc.*/sparc/' \
    -e 's/arm.*/arm/g' \
    -e 's/m68k.*/m68k/' \
    -e 's/ppc/powerpc/g' \
    -e 's/v850.*/v850/g' \
    -e 's/sh[234].*/sh/' \
    -e 's/mips.*/mips/' \
    -e 's/mipsel.*/mips/' \
    -e 's/cris.*/cris/' \
    -e 's/nios2.*/nios2/' \
	)
    echo $GCC_TARGET_ARCH
	# binutils ... 
	LOCAL_PATH="${CACHE_DIR}/staging/bin"

	# Cant use configure_generic here as we are running configure from a different directory
	# new funcion gcc_configure defined below
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	STAGING_DIR="${CACHE_DIR}/staging/"
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	CC="gcc" \
	gcc_configure \
		--prefix=${STAGING_DIR} \
		--build=${GCC_TARGET_ARCH}-pc-linux-gnu \
		--host=${GCC_TARGET_ARCH}-pc-linux-gnu \
		--target=${GCC_TARGET_ARCH}-linux-uclibc \
		--disable-altivec \
		--enable-nls \
		--enable-languages=c,c++ \
		--disable-shared \
		--with-sysroot=${STAGING_DIR} \
		--with-build-sysroot=${STAGING_DIR} \
		--disable-__cxa_atexit \
		--enable-target-optspace \
		--with-gnu-ld \
		--disable-nls \
		--disable-threads \
		--enable-multilib \
		--with-system-zlib \
		--disable-checking \
		--disable-werror \
		--disable-libunwind-exceptions \
		--disable-multilib \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libgcj \
		--enable-clocale=uclibc

	print_info 1 'gcc: >> Compiling...'
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	compile_generic all-gcc
		make all-gcc
	
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	compile_generic install-gcc
		make install-gcc
	
	cd ${CACHE_DIR}/staging
	genkernel_generate_package "gcc-stage2-${GCC_VER}" "."

	cd "${CACHE_DIR}"
	rm -rf "${CACHE_DIR}/${GCC_DIR}" > /dev/null
	rm -rf "${CACHE_DIR}/${GCC_BUILD_DIR}" > /dev/null
	rm -rf "${CACHE_DIR}/staging" > /dev/null
}

gcc_configure() {
	local RET
    print_info 2 "COMMAND: configure ${OPTS}" 1 0 1
	if [ "$(profile_get_key debuglevel)" -gt "1" ]
	then
		# Output to stdout and debugfile
		${CACHE_DIR}/${GCC_DIR}/configure "$@" 2>&1 | tee -a ${DEBUGFILE}
		RET=${PIPESTATUS[0]}
	else
		# Output to debugfile only
		${CACHE_DIR}/${GCC_DIR}/configure "$@" >> ${DEBUGFILE} 2>&1
		RET=$?
	fi
	[ "${RET}" -eq '0' ] || die "Failed to configure ..."
}
