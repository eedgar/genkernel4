require @pkg_uClibc-stage2-${UCLIBC_VER}:null:uclibc_stage2_compile

uclibc_stage2::() {
	mkdir -p ${TEMP}/staging
	cd ${TEMP}/staging
	genkernel_extract_package "uClibc-stage2-${UCLIBC_VER}"

}
