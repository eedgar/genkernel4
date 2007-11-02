require kernel
logicTrue $(external_initramfs) && require initramfs

links::()
{
	local ARGS CP_ARGS KNAME BOOTDIR

	BOOTDIR="$(profile_get_key bootdir)"
	KNAME="$(profile_get_key kernel-name)"
	if logicTrue $(profile_get_key install)
	then
		# link to the kernel
		print_info 1 ">> Creating link to kernel"
		if [ -n "$(profile_get_key install-path)" ]
		then
			print_info 1 ">> Creating link from $(profile_get_key install-path)/kernel-${KV_FULL} to $(profile_get_key install-path)/kernel"
			ln -sf "$(profile_get_key install-path)/kernel-${KV_FULL}" "$(profile_get_key install-path)/kernel"

		else
			print_info 1 ">> Creating link from ${BOOTDIR}/kernel-${KV_FULL} to ${BOOTDIR}/kernel"
			ln -sf "${BOOTDIR}/kernel-${KV_FULL}" "${BOOTDIR}/kernel"
		fi

		# link to System.map
		print_info 1 ">> Creating link to System.map"
		if [ -n "$(profile_get_key install-path)" ]
		then
			print_info 1 ">> Creating link from $(profile_get_key install-path)/System.map-${KV_FULL} to $(profile_get_key install-path)/System.map"
			ln -sf "$(profile_get_key install-path)/System.map-${KV_FULL}" "$(profile_get_key install-path)/System.map"

		else
			print_info 1 ">> Creating link from ${BOOTDIR}/System.map-${KV_FULL} to ${BOOTDIR}/System.map"
			ln -sf "${BOOTDIR}/System.map-${KV_FULL}" "${BOOTDIR}/System.map"
		fi

		# link to the initramfs
		if logicTrue $(external_initramfs)
		then
			if [ -n "$(profile_get_key install-initramfs-path)" ]
			then
				print_info 1 ">> Creating link from $(profile_get_key install-initramfs-path)/initramfs-${KV_FULL} to $(profile_get_key install-initramfs-path)/initramfs"
				ln -sf "$(profile_get_key install-initramfs-path)/initramfs-${KV_FULL}" "$(profile_get_key install-initramfs-path)/initramfs"
			else
				print_info 1 ">> Creating link from ${BOOTDIR}/initramfs-${KV_FULL} to ${BOOTDIR}/initramfs"
				ln -sf "${BOOTDIR}/initramfs-${KV_FULL}" "${BOOTDIR}/initramfs"
			fi
		fi
	else
		print_info 1 "Skipping link creation: --no-install enabled"
	fi
}
