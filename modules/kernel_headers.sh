require @pkg_kernel-headers-${KERNEL_HEADERS_VER}:null:kernel_headers_compile

kernel_headers::() {
	mkdir -p ${TEMP}/staging
	cd ${TEMP}/staging
	genkernel_extract_package "kernel-headers-${KERNEL_HEADERS_VER}"

}
