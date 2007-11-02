#!/bin/bash

# genkernel-modular/core/gen_profile.sh
# -- Core profile handling

# Copyright: 2006 plasmaroo@gentoo,org, rocket@gentoo.org
# License: GPLv2

declare -a __INTERNAL__OPTIONS__KEY # Key
declare -a __INTERNAL__OPTIONS__VALUE # = sign set
declare -a __INTERNAL__OPTIONS__PROFILE # Profile
declare -a __INTERNAL__OPTIONS__DELETED # Deleted flag
declare -a __INTERNAL__PROFILES

profile_create_index() {
	local i j indexed
	__INTERNAL__PROFILES=()
	for (( i = 0 ; i < ${#__INTERNAL__OPTIONS__PROFILE[@]}; ++i )) ; do
		if [ "${__INTERNAL__OPTIONS__DELETED[$i]}" == "0" ]
		then
			myMatched=false
			for (( j = 0 ; j < ${#__INTERNAL__PROFILES[@]}; ++j )) ; do
				if [ "${__INTERNAL__PROFILES[$j]%::::*}" = "${__INTERNAL__OPTIONS__PROFILE[$i]}" ]
				then
					myMatched=true
					__INTERNAL__PROFILES[$j]="${__INTERNAL__PROFILES[$j]}_${i}"
					break
				fi
			done

			if [ "${myMatched}" = 'false' ]
			then
				# First element of this profile
				__INTERNAL__PROFILES[${#__INTERNAL__PROFILES[@]}]="${__INTERNAL__OPTIONS__PROFILE[$i]}::::$i"
			fi
		fi
	done
}

profile_get_array_positions() {
	local i j
	for i in ${__INTERNAL__PROFILES[@]}
	do 
		if [ "${i%::::*}"  = "${1}" ]
		then
			j=${i#*::::}
			echo ${j//_/ }
			return
		fi
	done
}

profile_copy() {
	# <Source Profile> <Destination Profile (optional)> 

	[ "${1}" == "" ] && die "profile_copy <Source Profile> <Destination Profile (optional)>"
	[ "$2" = "" ] && __destination_profile="running" || __destination_profile="$2"
	local identifier values 

	for identifier in $(profile_list_keys $1); do
		# Get raw unprocessed key entry
		values=$(profile_get_key "${identifier}" "${1}" 'true' )
		profile_append_key "${identifier}" "${values}" "${__destination_profile}"
	done
}

profile_copy_key() {
	# <Source Profile> <key> <Destination Profile (optional)> 

	[ "${1}" == "" ] && die "profile_copy <Source Profile> <Destination Profile (optional)>"
	[ "${2}" == "" ] && die "profile_copy <Source Profile> <Destination Profile (optional)>"
	[ "${3}" = "" ] && __destination_profile="running" || __destination_profile="${3}"
	local identifier values 

	values=$(profile_get_key "${2}" "${1}" 'true')
	profile_append_key "${2}" "${values}" "${__destination_profile}"
}

profile_list_contents() {
	[ "$1" = "" ] && __destination_profile="running" || __destination_profile="$1"
	local identifier values arg
	for identifier in $(profile_list_keys ${__destination_profile}); do
		if [ "$(profile_get_key debuglevel)" -gt "4" ]
		then
			echo "${__destination_profile}[${identifier}]: $(profile_get_key "${identifier}" "${__destination_profile}" 'true' )"
		else
			echo "${__destination_profile}[${identifier}]: $(profile_get_key "${identifier}" "${__destination_profile}" )"
		fi
	done
}

profile_exists() {
	[ -n "$(profile_get_array_positions $__internal_profile)" ] && return 0 || return 1
}

profile_delete() {
	local n

	for n in $(profile_get_array_positions $__internal_profile) ; do
		${__INTERNAL__OPTIONS__DELETED[${n}]}='1'
	done
	
	# recreate the index as we have deleted a profile
	profile_create_index
	
}


profile_list() {
	local myOut n
	local array_length=${#__INTERNAL__OPTIONS__KEY[@]}
	for (( n = 0 ; n < ${array_length}; ++n )) ; do
		if ! has "${__INTERNAL__OPTIONS__PROFILE[${n}]}" "${myOut}"
		then
			[ ! "${__INTERNAL__OPTIONS__PROFILE[${n}]}" == "" ] && \
				myOut="${myOut} ${__INTERNAL__OPTIONS__PROFILE[${n}]}"
				myOut="${myOut# }"
				myOut="${myOut% }"

		fi
	done
	echo "${myOut}"
}

profile_delete_key() {
	local key deleted array_length=${#__INTERNAL__OPTIONS__KEY[@]} n __internal_profile z=0
	# faster to not use the cache as this would have to loop through the array anyway
	[ "$2" = "" ] && __internal_profile="running" || __internal_profile="$2"
	
	for n in $(profile_get_array_positions $__internal_profile); do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		deleted=${__INTERNAL__OPTIONS__DELETED[${n}]}

		if [ "$1" = "${key}" ]
		then	
			__INTERNAL__OPTIONS__DELETED[${n}]="1"
		fi
	done
	
	# deleted element need to update the index
	profile_create_index
}


profile_list_keys() {
	
	local key value profile n __internal_profile myOut
	# Requires profile index
	[ "$1" = "" ] && __internal_profile="running" || __internal_profile="$1"
	for n in $(profile_get_array_positions $__internal_profile); do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		myOut="${key} ${myOut}"
	done
	echo "${myOut}"
}

setup_system_profile() {
	# has to happen after the cmdline is processed.
	# Read arch-specific config
	PROFILE_CONFIG="${CONFIG_DIR}/profile.gk"
	[ -f "${PROFILE_CONFIG}" ] && config_profile_read ${PROFILE_CONFIG} "system"
}

setup_modules_profile() {
	# Read the generic kernel modules list first 
	GENERIC_MODULES_LOAD="${CONFIG_GENERIC_DIR}/modules_load.gk"
	[ -f "${GENERIC_MODULES_LOAD}" ] && config_profile_read ${GENERIC_MODULES_LOAD} "modules"

	# override with the config specific kernel modules
	MODULES_LOAD="${CONFIG_DIR}/modules_load.gk"
	[ -f "${MODULES_LOAD}" ] && config_profile_read ${MODULES_LOAD} "modules"
}


profile_get_key() {
	# <Key> <Profile (optional)> 
	# Requires profile index
	
	local n key value profile __internal_profile
	[ "$2" = "" ] && __internal_profile="running" || __internal_profile="$2"
	

	for n in $(profile_get_array_positions $__internal_profile) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}

		if [ "$1" = "${key}" ]
		then
			# want raw key .. no further processing necessary
			logicTrue ${3} && echo "${__INTERNAL__OPTIONS__VALUE[${n}]}" && return

			value=${__INTERNAL__OPTIONS__VALUE[${n}]}
			for i in ${value}
			do
				if [ "${i}" == "=" ]
				then
					equal_found="true"	
					positive_list=()
					negative_list=()
				elif [ "${i:0:3}" == "%%-" ]
				then
					if has "${i#%%-}"  "${positive_list}"
					then
						positive_list=$(subtract_from_list "${i#%%-}"  "${positive_list}")
					else
						if ! has "%%-${i}" "${negative_list}"
						then
							negative_list="${negative_list} ${i}"
						fi
					fi	
				else 	
					if has "%%-${i}" "${negative_list}"
					then
						negative_list=$(subtract_from_list "%%-${i}"  "${negative_list}")
					else
						if ! has "${i}" "${positive_list}"
						then
							positive_list="${positive_list} ${i}"
						fi
					fi
				fi
			done
			
			positive_list="${positive_list% }"
			positive_list="${positive_list# }"
			
			if [ "${equal_found}" == "true" ]
			then
				__INTERNAL__OPTIONS__VALUE[${n}]="= ${positive_list} ${negative_list}"
			else
				__INTERNAL__OPTIONS__VALUE[${n}]="${positive_list} ${negative_list}"
			fi
			
			echo ${positive_list}
			return

		fi
	done
}

profile_set_key() {
	# <Key> <Value> <Profile (optional)>
	# Requires profile index
	local i n key value profile __internal_profile length
	local equal_list="" positive_list="" negative_list=""
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"

	# Check key is not already set, if it is overwrite, else set it.
	for n in $(profile_get_array_positions $__internal_profile) ; do
		key=${__INTERNAL__OPTIONS__KEY[${n}]}
		value=${__INTERNAL__OPTIONS__VALUE[${n}]}
		profile=${__INTERNAL__OPTIONS__PROFILE[${n}]}
	
		if [ "${1}" = "${key}" ]
		then
			__INTERNAL__OPTIONS__KEY[${n}]="$1"
			__INTERNAL__OPTIONS__PROFILE[${n}]="$__internal_profile"
			__INTERNAL__OPTIONS__VALUE[${n}]="${2}"
			__INTERNAL__OPTIONS__DELETED[${n}]="0"
			return
		fi
	done

	# Unmatched
	length=${#__INTERNAL__OPTIONS__KEY[@]}
	__INTERNAL__OPTIONS__KEY[${length}]="$1"
	__INTERNAL__OPTIONS__VALUE[${length}]="${2}"
	__INTERNAL__OPTIONS__PROFILE[${length}]="$__internal_profile"
	__INTERNAL__OPTIONS__DELETED[${length}]="0"
	__INTERNAL__OPTIONS__OPTIMIZED[${n}]="false"
	
	# Added a new element need to update the index
	profile_create_index
}

profile_append_key() {
	# Direct access to the arrays will be faster in the end
	# <Key> <Value> <Profile (optional)>
	local n key orig_value new_value profile __internal_profile
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"
	
	# Get raw key
	orig_value="$(profile_get_key ${1} ${__internal_profile} 'true')"
	new_value="${orig_value} ${2}"
	
	new_value="${new_value% }"
	new_value="${new_value# }"
	profile_set_key "${1}" "${new_value}" "${__internal_profile}"
}

profile_shrink_key() {
	# <Key> <Value> <Profile (optional)>
	local n key value new_value profile __internal_profile
	[ "$3" = "" ] && __internal_profile="running" || __internal_profile="$3"
	
	orig_value="$(profile_get_key ${1} ${__internal_profile})"
	new_value="$(subtract_from_list "$2" "${orig_value}")"
	new_value=${new_value# }
	profile_set_key "${1}" "${new_value}" "${__internal_profile}"
	
	if [[ $(profile_get_key "${1}" "${__internal_profile}") == "" ]]
	then
		profile_delete_key "${1}" "${__internal_profile}"
	fi
}



# <file>
config_profile_read() {
	[ -f "$1" ] || die "parse_profile: No such file $1!"
	local identifier data set_config profile

	if [ -z "$2" ]
	then
		let number_cmdline_profiles=${number_cmdline_profiles}+1
		profile="cmdline-${number_cmdline_profiles}"
	else
		profile="${2}"
	fi
	__INTERNAL_PROFILES_READ="${__INTERNAL_PROFILES_READ} ${1}"
	while read i
	do
		# { identifier }{" := "}{quote}{data}{quote} or
		# "require "{profiles} or
		# "#"{comment}

		# Strip out inline comments
		i="${i/[ 	]\#*/}"

		if [[ ${i} =~ ^[a-z0-9-]+\ [-\+:]=\ .* ]]
		then
			if [[ ${i} =~ ^[a-z0-9\-]+\ : ]]
			then
				operator=':'
			elif [[ ${i} =~ ^[a-z0-9\-]+\ - ]] 
			then
				operator='-'
			else
				operator='+'
			fi
			
			identifier="${i% ${operator}=*}"
			data="${i#*${operator}= \"}" # Remove up to first quote inclusive
			data="${data%\"}" # Remove end quote
			
			case "${operator}" in
				':')
					profile_set_key "${identifier}" "= ${data}" "${profile}"
				;;
				'-')
					for j in ${data}
					do
						newdata="%%-${j} ${newdata}"
					done
					profile_append_key "${identifier}" "${newdata}" "${profile}"
				;;
				'+')
					profile_append_key "${identifier}" "${data}" "${profile}"
				;;
			esac

		elif [[ "${i}" =~ '^import ' ]]
		then
			identifier="${i/import /}"
			for j in "${identifier}"
			do
				if has "${j}" "${__INTERNAL_PROFILES_READ}"
				then
					echo "# Cyclic loop detected: ${j} required by ${1} but already processed."
				else
					config_profile_read "${j}" 
				fi
			done
		elif [[ "${i:0:1}" = '#' ]]
		then
			:
		elif [[ "${i}" = '' ]]
		then
			:
		else
			echo "# Invalid input: $i"
		fi
	done < $1

	[ -n "${set_config}" ] && echo "# Profile $1 set config vars:${set_config}"
}

config_profile_dump() {
	local j k separator data profile='user'
	
	for j in $(profile_list_keys "${profile}"); do
		case $j in
			profile|profile-dump)
				:
			;;
			*)
				# Get the raw key data
				data="$(profile_get_key $j "${profile}" 'true')"
				# Append keys by default unless set is specified
				separator="+="
				
				# reset lists to be blank
				element_list=""
				negative_list=""

				# Start building output string from the raw key data
				for k in ${data}; do
					if [ "${k}" == "=" ]
					then
						# use set key notation as an = was found
						element_list=""
						separator=":="
					else

						element_list="${element_list} ${k}"
					fi
				done
				
				for l in ${element_list}; do
					if [ "${l:0:3}" == "%%-" ]
					then
						negative_list="${negative_list} ${l#-}"
						element_list="$(subtract_from_list "$l" "${element_list}")"
					fi
				done
				
				# Remove items that are in both the positive and negative list as they cancel out
				for m in ${element_list}; do
					for n in ${negative_list}; do
						if [ "${m}" == "${n}" ]
						then
							element_list="$(subtract_from_list "$m" "${element_list}")"
							negative_list="$(subtract_from_list "$m" "${negative_list}")"
						fi
					done
				done
				
				element_list="${element_list# }"
				element_list="${element_list% }"
				negative_list="${negative_list# }"
				negative_list="${negative_list% }"
				
				[ -n "${element_list}" ] && echo "$j ${separator} \"${element_list}\""
				[ -n "${negative_list}" ] && echo "$j -= \"${negative_list}\""

			;;
		esac
	done
	
	exit 0
}



cmdline_modules_register(){
    local i data
    data=$1
    if [ "${data}" == "${data%:*}" ]
    then
        kernel_modules="${data}"
        category="extra"
    else
        kernel_modules="${data#*:}"
        category="${data%:*}"
    fi

    for i in $kernel_modules
    do
        profile_append_key "module-${category}" "${i}" "modules-cmdline"
        profile_append_key "module-${category}" "${i}" "cmdline"
    done
}

