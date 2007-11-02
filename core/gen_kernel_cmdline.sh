#!/bin/bash

# genkernel-modular/core/gen_kernel_cmdline.sh
# -- Kernel parameter callback system

# Copyright: 2006 rocket@gentoo.org
# License: GPLv2

declare -a __KERNEL_PARAM__REG__D # Data

kernel_cmdline_register_read() {
	local header_printed=0
	
	for (( n = 0 ; n < ${#__KERNEL_PARAM__REG__D[@]}; ++n )) ; do
		if [ "${header_printed}" != "1" ]
		then
			echo
			print_info 1 "Required Kernel Parameters:"
			header_printed=1
		fi
				
		print_info 1 "     ${__KERNEL_PARAM__REG__D[${n}]}"
	done
			
	if [ "${header_printed}" == "1" ]
	then
		echo
	fi
}

kernel_cmdline_register() {
	__KERNEL_PARAM__REG__D[${#__KERNEL_PARAM__REG__D[@]}]="${1}"
}

kernel_cmdline_unregister() {
	__KERNEL_PARAM__REG__D=()

}
