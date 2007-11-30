require @pkg_uClibc-stage2-${UCLIBC_VER}:null:uclibc_stage2_compile

uclibc_stage2::() {
	mkdir -p ${CACHE_DIR}/staging
	cd ${CACHE_DIR}/staging
	genkernel_extract_package "uClibc-stage2-${UCLIBC_VER}"

}
