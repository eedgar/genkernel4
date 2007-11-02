require @pkg_uClibc-stage1-${UCLIBC_VER}:null:uclibc_stage1_compile

uclibc_stage1::() {
	mkdir -p ${TEMP}/staging
	cd ${TEMP}/staging
	genkernel_extract_package "uClibc-stage1-${UCLIBC_VER}"

}
