require @pkg_kernel-headers-${KERNEL_HEADERS_VER}:null:kernel_headers_compile

#TODO .. generate the headers from the kernel_source tree as an option
kernel_headers::() {
	mkdir -p ${CACHE_DIR}/staging
	cd ${CACHE_DIR}/staging
	genkernel_extract_package "kernel-headers-${KERNEL_HEADERS_VER}"

}
