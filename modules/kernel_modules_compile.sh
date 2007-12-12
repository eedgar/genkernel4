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
	fi
}
