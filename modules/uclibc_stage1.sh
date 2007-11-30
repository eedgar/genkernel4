require @pkg_uClibc-stage1-${UCLIBC_VER}:null:uclibc_stage1_compile

uclibc_stage1::() {
	mkdir -p ${CACHE_DIR}/staging
	cd ${CACHE_DIR}/staging
	genkernel_extract_package "uClibc-stage1-${UCLIBC_VER}"

}
