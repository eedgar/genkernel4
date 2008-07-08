require @pkg_buildroot-${BUILDROOT_VER}:null:buildroot_compile
### XXX package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status
#package_check_register pkg_busybox-${BUSYBOX_VER} busybox::check_package_status

buildroot::() {
	mkdir -p ${CACHE_DIR}/buildroot
	cd ${CACHE_DIR}/buildroot
	genkernel_extract_package "buildroot-${BUILDROOT_VER}"
}
