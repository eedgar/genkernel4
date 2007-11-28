mount_boot::()
{
        test "$(id -u)" != "0" && return 


	local BOOTDIR
	BOOTDIR="$(profile_get_key bootdir)"

	if ! egrep -q "[[:space:]]${BOOTDIR}[[:space:]]" /proc/mounts
	then
		if egrep -q "^[^#].+[[:space:]]${BOOTDIR}[[:space:]]" /etc/fstab
		then
			if [ "${UID}" == "0" ]
			then
				if ! mount "${BOOTDIR}"
				then
					die "${BOLD}WARNING${NORMAL}: Failed to mount ${BOOTDIR}!"
				else
					print_info 1 "mount: ${BOOTDIR} mounted successfully!"
				fi
			else
				print_warning 1 ">> Skipping mount of ${BOOTDIR}. Not running as root."
			fi

		else
			print_warning 1 "${BOLD}WARNING${NORMAL}: No mounted ${BOOTDIR} mountpoint detected!"
			echo
		fi
	elif isBootRO
	then
		if [ "${UID}" == "0" ]
		then
			if ! mount -o remount,rw "${BOOTDIR}"
			then
				die "${BOLD}WARNING${NORMAL}: Failed to remount ${BOOTDIR} RW!"
			else
				print_info 1 "mount: ${BOOTDIR} remounted read/write successfully!"
			fi
		else
			print_warning 1 ">> Skipping remount of ${BOOTDIR}.  Not running as root."
		fi
	fi
}

isBootRO()
{
	return $(awk '( $2 == "'${BOOTDIR}'" && $4 ~ /(^|,)ro(,|$)/){ I=1; exit }END{print !I }' /proc/mounts);
}
