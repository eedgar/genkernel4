require kernel_modules_compile

kernel_modules_install::()
{
	# Set a few globals up
	# Set the destination path for the kernel modules
	if [ -z "$(profile_get_key install-mod-path)" ]
	then
	    profile_set_key install-mod-path "/"
	fi

	if [ -w $(dirname $(profile_get_key install-mod-path)) ]
	then
	    mkdir -p $(profile_get_key install-mod-path) || \
	        die "Could not make $(profile_get_key install-mod-path).  Set $(profile_get_key install-mod-path) to a writeable directory or run as root"
	else
	    print_info 1 ">> Kernel modules install path: ${BOLD}$(profile_get_key install-mod-path) ${NORMAL}is not writeable, attempting to use ${TEMP}/genkernel-output"
	    if [ ! -w ${TEMP} ]
	    then
	        die "Could not write to ${TEMP}/genkernel-output.  Set install-mod-path to a writeable directory or run as root"
	    else
	        mkdir -p ${TEMP}/genkernel-output || die "Could not make ${TEMP}/genkernel-output.  Set install-mod-path to a writeable directory or run as root"
	        profile_set_key install-mod-path "${TEMP}/genkernel-output"
	    fi
	fi

	if kernel_config_is_not_set "MODULES"
	then
		print_info 1 ">> Modules not enabled in .config... skipping modules install"
	else

		setup_kernel_args
	    KERNEL_ARGS="${KERNEL_ARGS} INSTALL_MOD_PATH=$(profile_get_key install-mod-path)"

		[ "$(profile_get_key debuglevel)" -gt "1" ] && print_info 1 ">> Installing kernel modules to $(profile_get_key install-mod-path)"

		cd $(profile_get_key kernel-tree)

		# install the modules
		print_info 1 '>> Installing kernel modules ...'
		compile_generic ${KERNEL_ARGS} modules_install
	fi
}
