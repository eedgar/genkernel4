#!/bin/bash

# genkernel-modular/core/gen_file_check.sh
# -- Downloaded files check system

# Copyright: 2006 rocket@gentoo.org
#            2007 Jean-Francois Richard <jean-francois@richard.name>
# License: GPLv2

declare -a __FILES_CHECK__REG__D # Data

files_register_read() {
    local header_printed=0
    
    for (( n = 0 ; n < ${#__FILES_CHECK__REG__D[@]}; ++n )) ; do
        if [ ! -f "${__FILES_CHECK__REG__D[${n}]}" ]
        then
            MISSING=1
	    print_info 1 "Source package $(basename ${__FILES_CHECK__REG__D[${n}]}) is missing"
        fi
    done

    if [ "${MISSING}" == "1" ]
    then
	print_info 1 "Downloading the missing files..."
	for (( n = 0 ; n < ${#__FILES_CHECK__REG__D[@]}; ++n )) ; do
            if [ ! -f "${__FILES_CHECK__REG__D[${n}]}" ]
            then
		cd "${SRCPKG_DIR}"

		# not very secure, waiting for a proper certificate from berlios.de...
		# at least it is encrypted :(
		wget --no-check-certificate --progress=bar -nc "https://genkernel.berlios.de/distfiles/$(basename ${__FILES_CHECK__REG__D[${n}]})"
		if [ "$?" != "0" ]; then
		    die "Could not auto-download missing source package $(basename ${__FILES_CHECK__REG__D[${n}]}) to ${SRCPKG_DIR}"
		fi

		cd - &>/dev/null
            fi
	done
    fi
}

files_register() {
    for (( n = 0 ; n <= ${#__FILES_CHECK__REG__D[@]}; ++n )) ;
    do
        if [ "$1" = "${__FILES_CHECK__REG__D[${n}]}" ]
        then
            return
        fi
    done
    
    __FILES_CHECK__REG__D[${#__FILES_CHECK__REG__D[@]}]="${1}"
}

files_unregister() {
    __FILES_CHECK__REG__D=()
}
