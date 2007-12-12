# genkernel-modular/core/gen_initramfs.sh
# -- Core initramfs handling subroutines

# Copyright: 2006 plasmaroo@gentoo,org, rocket@gentoo.org
# License: GPLv2

declare -a __INITRAMFS__REG__S # Source
declare -a __INITRAMFS__REG__D # Data

initramfs_register_cpio_read() {
	for (( n = 0 ; n <= ${#__INITRAMFS__REG__D[@]}; ++n )) ; do
		echo "${__INITRAMFS__REG__D[${n}]}"
	done
}

initramfs_register_cpio_lookup() {
	local source data

	for (( n = 0 ; n <= ${#__INITRAMFS__REG__D[@]}; ++n )) ; do
		source=${__INITRAMFS__REG__S[${n}]}
		data=${__INITRAMFS__REG__D[${n}]}

		[ "$1" = "${data}" ] && echo "${source}" && return
	done
}

initramfs_register_cpio () {
	local myCaller myCheck
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	# Check something does not already provide this image,
	# unless the module is the same in which case ignore the request.
	# If no clashes are found commit the change.

	for i in $*; do
		if [ ! -f "${TEMP}/$i.cpio.gz" ]
		then
			die "Invalid CPIO Registry request: ${i} -- file does not exist."
		fi

		myCheck=$(initramfs_register_cpio_lookup $i)

		if [ -n "${myCheck}" -a "${myCheck}" != "${myCaller}" ]
		then
			die "Conflicting cpio provide ($i in ${myCaller} against $i in ${myCheck})..."
		else
			__INITRAMFS__REG__S[${#__INITRAMFS__REG__S[@]}]="${myCaller}"
			__INITRAMFS__REG__D[${#__INITRAMFS__REG__D[@]}]="${TEMP}/$i.cpio.gz"
		fi
	done
}

initramfs_register_external_cpio () {
    local myCaller myCheck
    myCaller=$(basename ${BASH_SOURCE[1]} .sh)

    # Check something does not already provide this image,
    # unless the module is the same in which case ignore the request.
    # If no clashes are found commit the change.
    for i in $*; do
        if [ ! -f "${i}" ]
        then
            die "Invalid CPIO Registry request: ${i} -- file does not exist."
        fi

        myCheck=$(initramfs_register_cpio_lookup $i)
        if [ -n "${myCheck}" -a "${myCheck}" != "${myCaller}" ]
        then
            die "Conflicting cpio provide ($i in ${myCaller} against $i in ${myCheck})..."
        else
            __INITRAMFS__REG__S[${#__INITRAMFS__REG__S[@]}]="${myCaller}"
            __INITRAMFS__REG__D[${#__INITRAMFS__REG__D[@]}]="$i"
        fi
    done
}

