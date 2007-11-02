require @pkg_uClibc-${UCLIBC_VER}:null:uclibc_stage2_compile
### XXX package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status
#package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status

uclibc_stage2::() {
	[ -e ${TEMP}/staging ] && rm -r ${TEMP}/staging
	mkdir -p ${TEMP}/staging
	cd ${TEMP}/staging
	genkernel_extract_package "uClibc-stage2-${UCLIBC_VER}"

}
