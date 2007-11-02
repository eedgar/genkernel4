evms_host_compiled::() {
	if [ -e '/sbin/evms_activate' ]
	then
		if [ -d "${TEMP}/EVMS" ]
		then
			rm -r "${TEMP}/EVMS" 
		fi
		mkdir -p "${TEMP}/EVMS/lib/evms"
		mkdir -p "${TEMP}/EVMS/etc/"
		mkdir -p "${TEMP}/EVMS/bin/"
		mkdir -p "${TEMP}/EVMS/sbin/"
		cp -a /lib/ld-* "${TEMP}/EVMS/lib" || die 'Could not copy files for EVMS2!'
		cp -a /lib/libc-* /lib/libc.* "${TEMP}/EVMS/lib" || die 'Could not copy files for EVMS2!'
		cp -a /lib/libdl-* /lib/libdl.* "${TEMP}/EVMS/lib" || die 'Could not copy files for EVMS2!'
		cp -a /lib/libpthread* "${TEMP}/EVMS/lib" || die 'Could not copy files for EVMS2!'
		cp -a /lib/libuuid*so* "${TEMP}/EVMS/lib" || die 'Could not copy files for EVMS2!'
		cp -a /lib/libevms*so* "${TEMP}/EVMS/lib" || die 'Could not copy files for EVMS2!'
		cp -a /lib/evms "${TEMP}/EVMS/lib" || die 'Could not copy files for EVMS2!'
		cp -a /lib/evms/* "${TEMP}/EVMS/lib/evms" || die 'Could not copy files for EVMS2!'
		cp -a /etc/evms.conf "${TEMP}/EVMS/etc" || die 'Could not copy files for EVMS2!'
		cp /sbin/evms_activate "${TEMP}/EVMS/sbin/evms_activate" || die 'Could not copy over evms_activate!'
		# Fix EVMS2 complaining that it can't find the swap utilities.
		# These are not required in the initramfs
		for swap_libs in "${TEMP}/EVMS/lib/evms/*/swap*.so"
		do
			rm ${swap_libs}
		done
		
		cd ${TEMP}/EVMS
		# Will not cache this as the version of evms on the host system may change and we want
		# the newest one.
		genkernel_generate_cpio_path "evms-host-compiled" . || die "Could not create the cpio"
	    initramfs_register_cpio "evms-host-compiled" || die "Could not register evms cpio"
		
		message_register 'add "doevms2" for evms support'


	else
		die "Evms is not installed on your host system. Install it on your host sytem."
	fi
}
