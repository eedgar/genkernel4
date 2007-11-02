# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/linux-headers-${KERNEL_HEADERS_VER}.tar.bz2"

kernel_headers_compile::()
{
	local	KERNEL_HEADERS_SRCTAR="${SRCPKG_DIR}/linux-headers-${KERNEL_HEADERS_VER}.tar.bz2" 
	[ -f "${KERNEL_HEADERS_SRCTAR}" ] || die "Could not find kernel headers source tarball: ${KERNEL_HEADERS_SRCTAR}!"

	mkdir -p "${TEMP}/kh-staging"
	cd "${TEMP}/kh-staging"
	unpack ${KERNEL_HEADERS_SRCTAR} || die 'Could not extract kernel headers source tarball!'

	genkernel_generate_package "kernel-headers-${KERNEL_HEADERS_VER}" "."

	cd "${TEMP}"
	rm -rf "${TEMP}/kh-staging" > /dev/null
}
