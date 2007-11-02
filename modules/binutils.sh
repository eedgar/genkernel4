require @pkg_binutils-${BINUTILS_VER}:null:binutils_compile
### XXX package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status
#package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status

binutils::() {
	mkdir -p ${TEMP}/staging
	cd ${TEMP}/staging
	genkernel_extract_package "binutils-${BINUTILS_VER}"
}
