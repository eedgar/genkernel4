require kernel_config
logicTrue $(internal_initramfs) && require initramfs_create

kernel_compile::()
{
	setup_kernel_args
	cd $(profile_get_key kbuild-output)

	# Compile the kernel image
	print_info 1 '>> Compiling kernel ...'
	compile_generic ${KERNEL_ARGS} $(profile_get_key kernel-make-directive)
    RES=$?
    rm -rf "${TEMP}/kernel-compile" > /dev/null
    mkdir ${TEMP}/kernel-compile
    install -D "$(profile_get_key kernel-binary)" "${TEMP}/kernel-compile/$(profile_get_key kernel-binary)"
    cp "System.map" "${TEMP}/kernel-compile"
    cp .config "${TEMP}/kernel-compile"
    cd ${TEMP}/kernel-compile
    genkernel_generate_package "kernel-${KV_FULL}" "."
	cd $(profile_get_key kbuild-output)
    rm -r ${TEMP}/kernel-compile

	if [ "$RES" == "0" ]
	then
		print_info 1 ''
		print_info 1 "Kernel compiled successfully!"
		print_info 1 ''
	else
		print_info 1 'Do NOT report kernel bugs as genkernel bugs unless your bug'
		print_info 1 'is about the default genkernel configuration...'
		print_info 1 ''
		print_info 1 'Make sure you have the latest genkernel before reporting bugs.'
		print_info 1 ''
		die "Kernel Compilation failed.  Check your debuglog for details"
	fi
}
