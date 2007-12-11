require kernel_config
kernel_modules_compile::()
{
	if kernel_config_is_not_set "MODULES"
	then
		print_info 1 ">> Modules not enabled in .config... skipping modules compile"
	else
		setup_kernel_args
		cd $(profile_get_key kernel-tree)

		# make the modules
		print_info 1 '>> Preparing to compile kernel modules ...'
		compile_generic ${KERNEL_ARGS} modules_prepare
		
		print_info 1 '>> Compiling kernel modules ...'
		compile_generic ${KERNEL_ARGS} modules
		mkdir -p ${TEMP}/kernel-modules-compile
		KERNEL_ARGS="${KERNEL_ARGS} INSTALL_MOD_PATH=${TEMP}/kernel-modules-compile"
		compile_generic ${KERNEL_ARGS} modules_install
		cd ${TEMP}/kernel-modules-compile
		genkernel_generate_package "kernel-modules-${KV_FULL}" "."
		cd $(profile_get_key kernel-tree)
		rm -rf ${TEMP}/kernel-modules-compile
	fi
}
