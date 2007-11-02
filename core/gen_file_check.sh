#!/bin/bash

# genkernel-modular/core/gen_file_check.sh
# -- Downloaded files check system

# Copyright: 2006 rocket@gentoo.org
# License: GPLv2

declare -a __FILES_CHECK__REG__D # Data

files_register_read() {
	local header_printed=0
	
	for (( n = 0 ; n < ${#__FILES_CHECK__REG__D[@]}; ++n )) ; do
        if [ ! -f "${__FILES_CHECK__REG__D[${n}]}" ]
        then
            MISSING=1
        fi
    done
    if [ "${MISSING}" == "1" ]
    then
		echo
		print_info 1 "Missing Files Needed:"
	    for (( n = 0 ; n < ${#__FILES_CHECK__REG__D[@]}; ++n )) ; do
            if [ ! -f "${__FILES_CHECK__REG__D[${n}]}" ]
            then
		        print_info 1 "     ${__FILES_CHECK__REG__D[${n}]} is missing."
            fi
	    done
		echo
        die "Download missing files and rerun genkernel"
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
