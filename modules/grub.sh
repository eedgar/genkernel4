#require kernel initramfs

grub::() {
	local GRUB_CONF GRUB_BOOTFS GRUB_ROOTFS ARGS INITRAMFS_PRESENT KNAME BOOTDIR

	BOOTDIR="$(profile_get_key bootdir)"
	KNAME="$(profile_get_key kernel-name)"
	
	if logicTrue $(external_initramfs) 
	then
		INITRAMFS_PRESENT=1
	fi

	if [ -n "$(profile_get_key grub-conf)" ]
	then
		GRUB_CONF="$(profile_get_key grub-conf)"
	else
		GRUB_CONF="${BOOTDIR}/grub/grub.conf"
	fi

	# Create grub configuration directory and file if it doesn't exist.
	[ ! -e `basename $GRUB_CONF` ] && mkdir -p `basename $GRUB_CONF`
	print_info 1 ">> Adding kernel to $GRUB_CONF..."
	
	if [ -n "$(profile_get_key grub-bootfs)" ]
	then
		GRUB_BOOTFS="$(profile_get_key grub-bootfs)"
	else
		GRUB_ROOTFS=$(awk 'BEGIN{RS="((#[^\n]*)?\n)"}( $2 == "/" ) { print $1; exit }' /etc/fstab)
		GRUB_BOOTFS=$(awk 'BEGIN{RS="((#[^\n]*)?\n)"}( $2 == "'${BOOTDIR}'") { print $1; exit }' /etc/fstab)
		
		# If /boot is not defined in /etc/fstab, it must be the same as /
		[ "x$GRUB_BOOTFS" == 'x' ] && GRUB_BOOTFS=$GRUB_ROOTFS
	fi

	# Create and read GRUB device map
	/sbin/grub --batch --device-map=${TEMP}/grub.map <<EOF >/dev/null 2>&1
quit
EOF

	# Get the GRUB mapping for our device
	local GRUB_BOOT_DISK1=$(echo $GRUB_BOOTFS | sed -e 's#\(/dev/.\+\)[[:digit:]]\+#\1#')
	local GRUB_BOOT_DISK=$(awk '{if ($2 == "'$GRUB_BOOT_DISK1'") {gsub(/(\(|\))/, "", $1); print $1;}}' ${TEMP}/grub.map)

	local GRUB_BOOT_PARTITION=$(echo $GRUB_BOOTFS | sed -e 's#/dev/.\+\([[:digit:]]?*\)#\1#')

	if [ ! -e $GRUB_CONF ]
	then
		if [ "${GRUB_BOOT_DISK}" != '' -a "${GRUB_BOOT_PARTITION}" != '' ]
		then
			GRUB_BOOT_PARTITION=`expr ${GRUB_BOOT_PARTITION} - 1`
			# grub.conf doesn't exist - create it with standard defaults
			touch $GRUB_CONF
			echo 'default 0' >> $GRUB_CONF
			echo 'timeout 5' >> $GRUB_CONF
			echo >> $GRUB_CONF

			# Add grub configuration to grub.conf
			echo "# Genkernel generated entry, see GRUB documentation for details" >> $GRUB_CONF
			echo "title=Gentoo Linux ($KV_FULL)" >> $GRUB_CONF
			echo -e "\troot ($GRUB_BOOT_DISK,$GRUB_BOOT_PARTITION)" >> $GRUB_CONF
			
			if [ "${INITRAMFS_PRESENT}" == "0" ]
			then
				echo -e "\tkernel /kernel-${KV_FULL} root=/dev/ram0 init=/linuxrc real_root=$GRUB_ROOTFS" $(profile_get_key grub-options)>> $GRUB_CONF
			else
				echo -e "\tkernel /kernel-${KV_FULL} root=$GRUB_ROOTFS" $(profile_get_key grub-options)>> $GRUB_CONF
			fi
			
			if [ "${INITRAMFS_PRESENT}" == "0" ]
			then
				echo -e "\tinitrd /initramfs-${KV_FULL}" >> $GRUB_CONF
			fi

			echo >> $GRUB_CONF
		else
			print_error 1 "Error! $GRUB_CONF does not exist and the correct settings can not be automatically detected."
			print_error 1 "Please manually create your $GRUB_CONF file."
		fi
	else
		# grub.conf already exists; so...
		# ... Clone the first boot definition and change the version.
		cp $GRUB_CONF $GRUB_CONF.bak
		
		ARGS="${ARGS} KV=${KV_FULL}"
		ARGS="${ARGS} TYPE=ramfs"

		ARGS="${ARGS} INITRAMFS_PRESENT=${INITRAMFS_PRESENT}"
		[ "${GRUB_BOOT_DISK}" != '' ] && ARGS="${ARGS} GRUB_BOOT_DISK=${GRUB_BOOT_DISK}"
		[ "${GRUB_BOOT_PARTITION}" != '' ] && ARGS="${ARGS} GRUB_BOOT_PARTITION=${GRUB_BOOT_PARTITION}"
		
		local LIMIT=$(wc -l $GRUB_CONF.bak)
			
		ARGS="${ARGS} LIMIT=${LIMIT/ */}"
			
		awk -f ${CORE_DIR}/grub.awk \
		${ARGS} \
		$GRUB_CONF.bak > $GRUB_CONF
	fi
}
