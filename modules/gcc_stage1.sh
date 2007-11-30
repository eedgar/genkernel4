require @pkg_gcc-stage1-${GCC_VER}:null:gcc_stage1_compile
gcc_stage1::()
{
	mkdir -p ${CACHE_DIR}/staging
	cd ${CACHE_DIR}/staging
	genkernel_extract_package "gcc-stage1-${GCC_VER}"

    GCC_TARGET_ARCH=$(profile_get_key utils-arch)

	profile_set_key utils-cross-compile "${CACHE_DIR}/staging/bin/${GCC_TARGET_ARCH}-linux-uclibc-"

}
