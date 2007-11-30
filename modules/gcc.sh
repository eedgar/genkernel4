require @pkg_gcc-stage2-${GCC_VER}:null:gcc_stage2_compile

gcc::()
{
	mkdir -p ${CACHE_DIR}/staging
	cd ${CACHE_DIR}/staging
	genkernel_extract_package "gcc-stage2-${GCC_VER}"
    GCC_TARGET_ARCH=$(profile_get_key utils-arch)

	profile_set_key utils-cross-compile "${CACHE_DIR}/staging/bin/${GCC_TARGET_ARCH}-linux-uclibc"
}
