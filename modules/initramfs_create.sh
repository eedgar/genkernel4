logicTrue $(profile_get_key gmi) && require gmi
logicTrue $(profile_get_key busybox) && require busybox 
logicTrue $(profile_get_key kernel-modules-cpio) && require kernel_modules_cpio
logicTrue $(profile_get_key evms2) && require evms_host_compiled
logicTrue $(profile_get_key lvm2) && require lvm2
logicTrue $(profile_get_key e2fsprogs) && require e2fsprogs
logicTrue $(profile_get_key gensplash) && require gensplash
logicTrue $(profile_get_key portmap) && require portmap
logicTrue $(profile_get_key dmraid) && require dmraid
logicTrue $(profile_get_key open-iscsi) && require open_iscsi
logicTrue $(profile_get_key aoetools) && require aoetools
logicTrue $(profile_get_key luks) && require luks

# Get kernel modules
# Register a new cpio of the kernel modules

initramfs_create::() {
	# Add any external cpios if defined
	[ -n "$(profile_get_key external-cpio)" ] && initramfs_register_external_cpio $(profile_get_key external-cpio)
	
	# Add the initramfs-overlay 	
	if [ -n "$(profile_get_key initramfs-overlay)" ]
	then
		cd "$(profile_get_key initramfs-overlay)" \
			|| die "Failed to generate the initramfs overlay from $(profile_get_key initramfs-overlay)"
		genkernel_generate_cpio_path initramfs-overlay .
		initramfs_register_cpio initramfs-overlay
	fi

	if logicTrue $(profile_get_key internal-initramfs)
	then
		# Build a single uncompressed cpio file
		print_info 1 'Preparing internal initramfs directory space'
		
		if [ -d "${TEMP}/initramfs-internal" ]
		then
			rm -r "${TEMP}/initramfs-internal" 
		fi

		mkdir "${TEMP}/initramfs-internal"
		
		for i in $(initramfs_register_cpio_read)
		do
			if [ ! -f "$i" ]
			then
				die "Invalid CPIO file in registry: ${i} -- file does not exist."
			fi
			genkernel_extract_cpio $i "${TEMP}/initramfs-internal"
			cat <<- EOF > ${TEMP}/initramfs-internal.devices
			nod /dev/console 0600 0 0 c 5 1
			nod /dev/null 0600 0 0 c 1 3
			nod /dev/tty1 0600 0 0 c 4 1
			EOF

		done
	else
		print_info 1 'Merging:'
		[ -e "${TEMP}/initramfs-output.cpio.gz" ] && rm "${TEMP}/initramfs-output.cpio.gz"
		if logicTrue $(profile_get_key single-cpio)
		then
			print_info 1 'Creating Single Cpio File'
			# Build a single cpio file
		
			if [ -d "${TEMP}/initramfs-internal" ]
			then
				rm -r "${TEMP}/initramfs-internal" 
			fi

			mkdir "${TEMP}/initramfs-internal"
		
			for i in $(initramfs_register_cpio_read)
			do
				if [ ! -f "$i" ]
				then
					die "Invalid CPIO file in registry: ${i} -- file does not exist."
				fi
				genkernel_extract_cpio $i "${TEMP}/initramfs-internal"
			done
			cd "${TEMP}/initramfs-internal"
			genkernel_generate_cpio_path initramfs-output .

		else
		for i in $(initramfs_register_cpio_read)
		do
			if [ ! -f "$i" ]
			then
				die "Invalid CPIO file in registry: ${i} -- file does not exist."
			fi
			if [ "$(dirname ${i})" == "${TEMP}" ]
			then
				print_info 1 "    $(basename ${i} .cpio.gz)"
			else
				print_info 1 "    ${i}"
			fi

			# Can't use < file; bash seems to barf on binary data...
			cat "$i" >> "${TEMP}/initramfs-output.cpio.gz"
		done
	fi
fi
}
