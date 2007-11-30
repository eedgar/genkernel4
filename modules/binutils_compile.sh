require uclibc_stage1

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/binutils-${BINUTILS_VER}.tar.bz2"

binutils_compile::()
{
	local	BINUTILS_SRCTAR="${SRCPKG_DIR}/binutils-${BINUTILS_VER}.tar.bz2" BINUTILS_DIR="binutils-${BINUTILS_VER}" 
	[ -f "${BINUTILS_SRCTAR}" ] || die "Could not find binutils source tarball: ${BINUTILS_SRCTAR}!"

	#cd "${TEMP}"
	cd "${CACHE_DIR}"
	rm -rf ${BINUTILS_DIR} > /dev/null
	unpack ${BINUTILS_SRCTAR} || die 'Could not extract binutils source tarball!'
	[ -d "${BINUTILS_DIR}" ] || die 'Binutils directory ${BINUTILS_DIR} is invalid!'

	cd "${BINUTILS_DIR}"
	
	gen_patch ${FIXES_PATCHES_DIR}/binutils/${BINUTILS_VER} .

	print_info 1 'binutils: >> Configuring...'
    BINUTILS_TARGET_ARCH=$(profile_get_key utils-arch)
	
    CC="gcc" \
	configure_generic \
	--prefix=${CACHE_DIR}/staging \
        --build=${BINUTILS_TARGET_ARCH}-pc-linux-gnu \
        --host=${BINUTILS_TARGET_ARCH}-pc-linux-gnu \
        --target=${BINUTILS_TARGET_ARCH}-linux-uclibc \
        --disable-nls \
        --enable-multilib \
        --disable-werror \
        --with-sysroot="${CACHE_DIR}/staging/"

	print_info 1 'binutils: >> Compiling...'
	compile_generic all
	
	
	mkdir ${CACHE_DIR}/staging
	
	compile_generic install
	
	cd ${CACHE_DIR}/staging
	genkernel_generate_package "binutils-${BINUTILS_VER}" "."

	cd "${CACHE_DIR}"
	rm -rf "${BINUTILS_DIR}" > /dev/null
}
