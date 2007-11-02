#!/bin/bash

# genkernel-modular/core/gen_cfg.sh
# -- Core configuration queing routines

# Copyright: 2006 plasmaroo@gentoo.org, rocket@gentoo.org
# License: GPLv2

declare -a __CONFIG__REG__S # Source
declare -a __CONFIG__REG__D # Data
declare -a __CONFIG__REG__V # Default Value
declare -a __CONFIG__REG__M # Missing Message

cfg_register_read() {
	local header_printed=0
	
	for (( n = 0 ; n < ${#__CONFIG__REG__D[@]}; ++n )) ; do
		if kernel_config_is_not_set ${__CONFIG__REG__D[${n}]}
		then
			if [ "${header_printed}" != "1" ]
			then
				echo
				print_warning 1 "YOU HAVE THE FOLLOWING KERNEL CONFIG OPTIONS ${BOLD}DISABLED!"
				header_printed=1
			fi
				
			if [ "${__CONFIG__REG__M[${n}]}" != "" ]
			then
				print_warning 1 "CONFIG_${__CONFIG__REG__D[${n}]}: ${__CONFIG__REG__M[${n}]} "
			else
				print_warning 1 "CONFIG_${__CONFIG__REG__D[${n}]} is missing. You may have problems booting your system..."
			fi
		fi
	done
			
	if [ "${header_printed}" == "1" ]
	then
		echo
	fi
}

cfg_register_enable() {
	for (( n = 0 ; n < ${#__CONFIG__REG__D[@]}; ++n )) ; do
        echo "${__CONFIG__REG__D[${n}]}"
		if kernel_config_is_not_set ${__CONFIG__REG__D[${n}]}
		then
			UPDATED_KERNEL=true
			
			if [ "${__CONFIG__REG__V[${n}]}" == "m" ]
			then
				if kernel_config_is_not_set "MODULES"
				then
					print_info 1 "Turning on ${__CONFIG__REG__D[${n}]} as a builtin"
					kernel_config_set_builtin "${__CONFIG__REG__D[${n}]}"
				else
					print_info 1 "Turning on ${__CONFIG__REG__D[${n}]} as a module"
					kernel_set_config_module ${__CONFIG__REG__D[${n}]}
				fi
			elif [ "${__CONFIG__REG__V[${n}]}" == "y" ]
			then
				print_info 1 "Turning on ${__CONFIG__REG__D[${n}]} as a builtin"
				kernel_config_set_builtin "${__CONFIG__REG__D[${n}]}"
			elif [ "${__CONFIG__REG__V[${n}]}" == "n" ]
			then
				print_info 1 "Turning off ${__CONFIG__REG__D[${n}]}"
				kernel_config_unset "${__CONFIG__REG__D[${n}]}"
			else
				print_info 1 "Setting ${__CONFIG__REG__D[${n}]} to ${__CONFIG__REG__V[${n}]}"
				kernel_config_set_string "${__CONFIG__REG__D[${n}]}" "${__CONFIG__REG__V[${n}]}"
			fi
		fi
	done
}

cfg_register_lookup() {
	local data

	for (( n = 0 ; n < ${#__CONFIG__REG__D[@]}; ++n )) ; do
		data=${__CONFIG__REG__D[${n}]}
		[ "$1" = "${data}" ] && return 0
	done
	return 1
}

cfg_register() {
    local myCaller myCheck
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	if ! cfg_register_lookup $1
	then
		__CONFIG__REG__S[${#__CONFIG__REG__S[@]}]="${myCaller}"
		__CONFIG__REG__D[${#__CONFIG__REG__D[@]}]="${1}"
		__CONFIG__REG__M[${#__CONFIG__REG__M[@]}]="${2}"
		if [ "${3}" == "" ]
		then
			__CONFIG__REG__V[${#__CONFIG__REG__V[@]}]="y"
		else
			__CONFIG__REG__V[${#__CONFIG__REG__V[@]}]="${3}"
		fi
	fi
}
