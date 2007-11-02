require initramfs_create

initramfs_install::() {
	# Set up a few globals
	# Set the destination path for the initramfs
	if ! logicTrue $(profile_get_key internal-initramfs)
	then
		if [ -z "$(profile_get_key install-initramfs-path)" ]
		then
	    		profile_set_key install-initramfs-path "$(profile_get_key bootdir)"
		fi

		if [ -w $(dirname $(profile_get_key install-initramfs-path)) ]
		then
	    		mkdir -p $(profile_get_key install-initramfs-path) || \
	       		die "Could not make $(profile_get_key install-initramfs-path).  Set $(profile_get_key install-initramfs-path) to a writeable directory or run as root"
		else
    		print_info 1 ">> Initramfs install path:
            ${BOLD}$(profile_get_key install-initramfs-path) ${NORMAL}is not writeable, attempting to use ${TEMP}/genkernel-output/boot"
    			if [ ! -w ${TEMP} ]
    			then
    		   	 	die "Could not write to ${TEMP}/genkernel-output.  Set install-initramfs-path to a writeable directory or run as root"
    			else
        			mkdir -p ${TEMP}/genkernel-output/boot || die "Could not make ${TEMP}/genkernel-output/boot.  Set install-initramfs-path to a writeable directory or run as root"
        			profile_set_key install-initramfs-path "${TEMP}/genkernel-output/boot"
    			fi
		fi
	fi

	local ARGS KNAME
	if logicTrue $(profile_get_key internal-initramfs)
	then
		print_info 1 "Skipping installation of the initramfs: --initramfs-internal enabled"
	else
		[ "$(profile_get_key debuglevel)" -gt "1" ] && ARGS="-v"
		print_info 1 ">> Installing initramfs to $(profile_get_key install-initramfs-path)/initramfs-${KV_FULL}"
		cp ${ARGS} "${TEMP}/initramfs-output.cpio.gz" "$(profile_get_key install-initramfs-path)/initramfs-${KV_FULL}"
	fi
}
