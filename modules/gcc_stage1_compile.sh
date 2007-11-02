require binutils

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/gcc-${GCC_VER}.tar.bz2"

gcc_stage1_compile::()
{
	local GCC_SRCTAR="${SRCPKG_DIR}/gcc-${GCC_VER}.tar.bz2"
	local GCC_DIR="gcc-${GCC_VER}"
	local GCC_BUILD_DIR="gcc-${GCC_VER}-build"
	[ -f "${GCC_SRCTAR}" ] || die "Could not find gcc source tarball: ${GCC_SRCTAR}!"

	cd "${TEMP}"
	rm -rf ${GCC_DIR} > /dev/null
	unpack ${GCC_SRCTAR} || die 'Could not extract gcc source tarball!'
	[ -d "${GCC_DIR}" ] || die 'gcc directory ${GCC_DIR} is invalid!'

	# Apply patches
	cd "${GCC_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/gcc/${GCC_VER} .
	
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

	# binutils ... 
	LOCAL_PATH="${TEMP}/staging/bin"

	# Cant use configure_generic here as we are running configure from a different directory
	# new funcion gcc_configure defined below
	
	STAGING_DIR=${TEMP}/staging/

	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	CC="gcc" \
	gcc_configure \
		--prefix=${STAGING_DIR} \
		--build=${GCC_TARGET_ARCH}-pc-linux-gnu \
		--host=${GCC_TARGET_ARCH}-pc-linux-gnu \
		--target=${GCC_TARGET_ARCH}-linux-uclibc \
		--enable-languages=c \
		--disable-shared \
		--with-sysroot=${STAGING_DIR} \
		--disable-__cxa_atexit \
		--enable-target-optspace \
		--with-gnu-ld \
		--disable-nls \
		--disable-threads \
		--enable-multilib


	print_info 1 'gcc: >> Compiling...'
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	compile_generic all-gcc
#		make all-gcc
	
	PATH="${LOCAL_PATH}:/bin:/sbin:/usr/bin:/usr/sbin" \
	compile_generic install-gcc
#		make install-gcc
	
	cd ${TEMP}/staging
	genkernel_generate_package "gcc-stage1-${GCC_VER}" "."

	cd "${TEMP}"
	rm -rf "${TEMP}/${GCC_DIR}" > /dev/null
	rm -rf "${TEMP}/${GCC_BUILD_DIR}" > /dev/null
	rm -rf "${TEMP}/staging" > /dev/null
}

gcc_configure() {
	local RET
    print_info 2 "COMMAND: configure ${OPTS}" 1 0 1
	if [ "$(profile_get_key debuglevel)" -gt "1" ]
	then
		# Output to stdout and debugfile
		${TEMP}/${GCC_DIR}/configure "$@" 2>&1 | tee -a ${DEBUGFILE}
		RET=${PIPESTATUS[0]}
	else
		# Output to debugfile only
		${TEMP}/${GCC_DIR}/configure "$@" >> ${DEBUGFILE} 2>&1
		RET=$?
	fi
	[ "${RET}" -eq '0' ] || die "Failed to configure ..."
}

