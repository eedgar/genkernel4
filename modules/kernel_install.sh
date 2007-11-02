require kernel_compile

kernel_install::()
{
	# Set up some globals
	# Set the destination path for the kernel
	if [ -z "$(profile_get_key install-path)" ]
	then
		profile_set_key install-path "$(profile_get_key bootdir)"
	fi

	if [ -w $(dirname $(profile_get_key install-path)) ]
	then
		mkdir -p $(profile_get_key install-path) || \
			die "Could not make $(profile_get_key install-path).  Set $(profile_get_key install-path) to a writeable directory or run as root"
	else
		print_info 1 ">> Kernel install path: ${BOLD}$(profile_get_key install-path) ${NORMAL}is not writeable, attempting to use ${TEMP}/genkernel-output"
		if [ ! -w ${TEMP} ]
		then
			die "Could not write to ${TEMP}/genkernel-output.  Set install-path to a writeable directory or run as root"
		else
			mkdir -p ${TEMP}/genkernel-output/boot || die "Could not make ${TEMP}/genkernel-output/boot/.  Set install-path to a writeable directory or run as root"
			profile_set_key install-path "${TEMP}/genkernel-output/boot/"
		fi
	fi
	KERNEL_ARGS="${KERNEL_ARGS} INSTALL_PATH=$(profile_get_key install-path)"

	local CP_ARGS KNAME

	KNAME="$(profile_get_key kernel-name)"
	
	setup_kernel_args
	cd "$(profile_get_key kbuild-output)"

	print_info 1 '>> Installing kernel ...'

	[ "$(profile_get_key debuglevel)" -gt "1" ] && CP_ARGS="-v"
	[ "$(profile_get_key debuglevel)" -gt "1" ] &&\
		print_info 1 ">> Installing kernel to $(profile_get_key install-path)/kernel-${KV_FULL}"
	cp ${CP_ARGS} "$(profile_get_key kernel-binary)" "$(profile_get_key install-path)/kernel-${KV_FULL}"
	cp ${CP_ARGS} "System.map" "$(profile_get_key install-path)/System.map-${KV_FULL}"

	if [ -w /etc/kernels ]
	then
		profile_set_key kernel-config-destination-path "/etc/kernels"
	else
		print_info 1 ">> Kernel config install path: ${BOLD}/etc/kernels${NORMAL} is not writeable attempting to use ${TEMP}/genkernel-output"
		if [ ! -w ${TEMP} ]
		then
			die "Could not write to ${TEMP}/genkernel-output."
		else
			mkdir -p ${TEMP}/genkernel-output/etc/kernels || die "Could not make ${TEMP}/genkernel-output."
			profile_set_key kernel-config-destination-path "${TEMP}/genkernel-output/etc/kernels"
		fi
	fi
	
	cp .config "$(profile_get_key kernel-config-destination-path)/kernel-config-${KV_FULL}"
	print_info 1 "Kernel config file saved to $(profile_get_key kernel-config-destination-path)/kernel-config-${KV_FULL}"

}
