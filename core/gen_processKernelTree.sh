# genkernel-modular/core/gen_processKernelTree.sh
# -- Core kernel tree processing

# Copyright: 2006 plasmaroo@gentoo,org, rocket@gentoo.org
#            2007 Jean-Francois Richard <jean-francois@richard.name>
#            Portions copyright 1999-2006 Gentoo Foundation
# License: GPLv2

get_KV() {
    KNAME="$(profile_get_key kernel-name)"
    
    KERNEL_DIR="$1"
    [ ! -e "$1/Makefile" ] && die "Kernel source tree '$KERNEL_DIR' invalid, no Makefile found!"
        
    if [ -f "$(profile_get_key kbuild-output)/localversion-genkernel" ]
    then
	version_string=$(cat $(profile_get_key kbuild-output)/localversion-genkernel)
    fi
    
    if [ "${version_string}" != "-${KNAME}-${ARCH}" ]
    then
	if [ "${KNAME}" != 'do-not-set' ]
	then
	    echo "-${KNAME}-${ARCH}" > "$(profile_get_key kbuild-output)/localversion-genkernel" || die "No permissions to write to $(profile_get_key kbuild-output)/localversion-genkernel"
	else
	    rm "$(profile_get_key kbuild-output)/localversion-genkernel" 2>/dev/null
	fi
    fi
    
    # Configure the kernel
    KV_MAJOR=`grep ^VERSION\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
    KV_MINOR=`grep ^PATCHLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
    KV_PATCH=`grep ^SUBLEVEL\ \= ${KERNEL_DIR}/Makefile | awk '{ print $3 };'`
    
    if [ -z "${KV_PATCH}" ]
    then
        die "Error in kernel tree.  Kernel Patch Level could not be found."
    fi
    
    KV_CODE="$(linux_kv_to_code ${KV_MAJOR} ${KV_MINOR} ${KV_PATCH})"
    KV_EXTRA=`grep ^EXTRAVERSION\ \= ${KERNEL_DIR}/Makefile | sed -e "s/EXTRAVERSION =//" -e "s/ //g" -e 's/\$([a-z]*)//gi'`
    KV_LOCAL=""
	
    # Local version
    local myLookup myList

#[[ -e "${KERNEL_DIR}/localversion" ]] && myList='localversion'
#
#	[[ -n "$(ls ${KERNEL_DIR}/localversion*[^~] 2>/dev/null)" ]] && myList="${myList} $(ls ${KERNEL_DIR}/localversion*[^~])"
#	[[ -n "$(ls ${KBUILD_OUTPUT}/localversion*[^~] 2>/dev/null)" ]] && myList="${myList} $(ls ${KBUILD_OUTPUT}/localversion*[^~])"
#	
#	for i in "${myList}"
#	do
#		if [ "${i}" == '' ]
#		then
#			continue
#		else
#			echo \"$i\"
#			var=$(cat $i)
#			echo $var
#			#KV_LOCAL="${KV_LOCAL}${var}"
#		fi
#	done

    if [ -f ${KBUILD_OUTPUT}/.config ]
    then
	myLookup="$(get_extconfig_var ${KBUILD_OUTPUT}/.config CONFIG_LOCALVERSION)"
	[ "${myLookup}" != '%lookup_fail%' ] && KV_LOCAL="${KV_LOCAL}${myLookup}"
    fi
	
    KV_LOCAL="${KV_LOCAL// /}"
    if [ -f ${KBUILD_OUTPUT}/include/linux/utsrelease.h ]
    then
	UTS_RELEASE=`grep UTS_RELEASE ${KBUILD_OUTPUT}/include/linux/utsrelease.h | sed -e 's/#define UTS_RELEASE "\(.*\)"/\1/'`
	KV_LOCAL=`echo ${UTS_RELEASE}|sed -e "s/${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}//"`
    elif [ -f ${KBUILD_OUTPUT}/include/linux/version.h ]
    then
	UTS_RELEASE=`grep UTS_RELEASE ${KBUILD_OUTPUT}/include/linux/version.h | sed -e 's/#define UTS_RELEASE "\(.*\)"/\1/'`
	KV_LOCAL=`echo ${UTS_RELEASE}|sed -e "s/${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}//"`
    fi
    
    if [ "${KV_MINOR}" -lt '6' -a "${KV_MAJOR}" -eq '2' ]
    then
	die 'Kernel unsupported (2.6 or newer needed); exiting.'
    fi
    
    KV_FULL="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}${KV_LOCAL}"
}

genkernel_lookup_kernel() {
	get_KV $(profile_get_key kernel-tree)

	[ "$1" != 'silent' ] && print_info 1 "Kernel Tree: Linux kernel ${BOLD}${KV_FULL}${NORMAL} for ${BOLD}$(profile_get_key arch)${NORMAL}, at $(profile_get_key kernel-tree)"
	provide kernel_src_tree
}

get_extconfig_var() {
	# Check "$1" and return data of the token "$2=data"
	local myOut

	myOut="$(grep -m 1 $2 $1)"
	if [ "$?" -ne '0' ]
	then
		echo '%lookup_fail%'
		return
	fi

	# ... So it worked
	# Strip $2= out of the grep to get our result
	myOut="${myOut#$2=}"

	# Get rid of any double quotes
	echo "${myOut//\"/}"
}

kernel_is() {
	#[operator] [version2]
	linux_kv_cmp "${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}" $1 $2
}

linux_kv_cmp() {
	# [version1] [operator] [version2]

	local a=$1 b=$3 operator
	case ${2} in
	  lt) operator="-lt"; shift;;
	  gt) operator="-gt"; shift;;
	  le) operator="-le"; shift;;
	  ge) operator="-ge"; shift;;
	  eq) operator="-eq"; shift;;
	   *) operator="-eq";;
	esac

	# See if our version is non-numerical and if so convert
	[ "$a" != "${a/[. ]//}" ] && a="$(linux_kv_to_code ${a})"
	[ "$b" != "${b/[. ]//}" ] && b="$(linux_kv_to_code ${b})"

	[ ${a} "${operator}" ${b} ]
	return $?
}

# Arguments: {(a)(b)(c)}|{"a.b.c"}|{"a b c"}
# Output: Magnitude comparable integer
linux_kv_to_code() {
	local a b c in
	if [ "$#" -eq '1' ]
	then
		in=${1//./ }
		a=${in%% *}
		b=${in#* }
		b=${b%% *}
		c=${in##* }
		echo "$(( ($a << 16) + ($b << 8) + $c ))"
	else
		echo "$(( ($1 << 16) + ($2 << 8) + $3 ))"
	fi
}

check_asm_link_ok() {
	workingdir=${PWD}
	if [ -e "${KBUILD_OUTPUT}/include/asm" ]
	then
		cd ${KBUILD_OUTPUT}/include
		if [ -h "asm" ]
		then 
			asmlink="$(readlink -f asm)"
			if [ $(basename ${asmlink}) == "asm-${1}" ]
			then
				cd ${workingdir}
				return 0
			else
				cd ${workingdir}
				return 1
			fi
		fi	
	else
		cd ${workingdir}
		# No link setup yet which is ok...
		return 0
	fi
}

# this is mainly for setting integers, but the other kernel_config_set could be
# refactored to use it.
kernel_config_set_raw() {
	sed -i ${KBUILD_OUTPUT}/.config -e "s|#\? \?CONFIG_${1} is.*|CONFIG_${1}=${2}|g" 2>/dev/null
	sed -i ${KBUILD_OUTPUT}/.config -e "s|CONFIG_${1}=.*|CONFIG_${1}=${2}|g" 2>/dev/null
	if ! kernel_config_is_set ${1}
	then
		echo "CONFIG_${1}=${2}" >> ${KBUILD_OUTPUT}/.config
	fi
}

kernel_config_set_string() {
	key="${1}"
	shift
	kernel_config_set_raw "${key}" "\"${*}\""
}

kernel_config_set_builtin() {
	# TODO need to check for null entry entirely
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=m/CONFIG_${1}=y/g" 2>/dev/null
	sed -i ${KBUILD_OUTPUT}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=y/g" 2>/dev/null
	if ! kernel_config_is_set ${1}
	then
		echo "CONFIG_${1}=y" >> ${KBUILD_OUTPUT}/.config
	fi
}

kernel_config_set_module() {
	# TODO need to check for null entry entirely
	sed -i ${KBUILD_OUTPUT}/.config -e "s/CONFIG_${1}=y/CONFIG_${1}=m/g" 2>/dev/null
	sed -i ${KBUILD_OUTPUT}/.config -e "s/#\? \?CONFIG_${1} is.*/CONFIG_${1}=m/g" 2>/dev/null
	if ! kernel_config_is_set ${1}
	then
		echo "CONFIG_${1}=m" >> ${KBUILD_OUTPUT}/.config
	fi
}

kernel_config_unset() {
	sed -i "${KBUILD_OUTPUT}"/.config -e "s/CONFIG_${1}=.*/# CONFIG_${1} is not set/g" 2>/dev/null
}

# you should check kernel_config_is_set before trusting this, beware
kernel_config_get() {
	local RET_STR
	RET_STR=$(grep "CONFIG_$1=" "${KBUILD_OUTPUT}"/.config 2>/dev/null)
	echo "${RET_STR#*=}"
}

# These should be tweaked to use kernel_config_get perhaps?
kernel_config_is_builtin() {
	local RET_STR
	RET_STR=$(grep "CONFIG_$1=y" "${KBUILD_OUTPUT}"/.config 2>/dev/null)
	[ "${RET_STR}" == "CONFIG_$1=y" ] && return 0 || return 1
}

kernel_config_is_module() {
	local RET_STR
	RET_STR=$(grep "CONFIG_$1=m" "${KBUILD_OUTPUT}"/.config 2>/dev/null)
	[ "${RET_STR}" == "CONFIG_$1=m" ] && return 0 || return 1
}

kernel_config_is_set() {
	local RET_STR
	RET_STR=$(grep "CONFIG_$1=" "${KBUILD_OUTPUT}"/.config 2>/dev/null)
	[ "${RET_STR%%=*}=" == "CONFIG_$1=" ] && return 0 || return 1
}

kernel_config_is_not_set() {
	local RET_STR
	RET_STR=$(grep "CONFIG_$1" "${KBUILD_OUTPUT}"/.config 2>/dev/null)
	[ "${RET_STR}" == "# CONFIG_$1 is not set" ] && return 0 
	[ "${RET_STR}" == "" ] && return 0 
	return 1
}


determine_config_file() {

    rm "${TEMP}/from-running-system.config" 2>/dev/null

    if [ -f "/proc/config.gz" ]; then
	zcat /proc/config.gz > "${TEMP}/from-running-system.config" 2> /dev/null
	logicTrue $(profile_get_key running-kernel-config) && \
	    profile_set_key kernel-config "${TEMP}/from-running-system.config"
    else
	logicTrue $(profile_get_key running-kernel-config) && \
            die 'Error: /proc/config.gz is not found.  Running-kernel-config failed!'
    fi

    if [ -n "$(profile_get_key kernel-config)" ]; then
	KERNEL_CONFIG="$(profile_get_key kernel-config)"
	
    elif [ -f "/etc/kernels/kernel-config-${KV_FULL}" ]; then
	KERNEL_CONFIG="/etc/kernels/kernel-config-${KV_FULL}"

    elif [ -f "${TEMP}/from-running-system.config" ]; then
	KERNEL_CONFIG="${TEMP}/from-running-system.config"

    elif [ -f "${CONFIG_DIR}/kernel-config-${KV_FULL}" ]; then
	KERNEL_CONFIG="${CONFIG_DIR}/kernel-config-${KV_FULL}"
	
    elif [ -f "${CONFIG_DIR}/kernel-config-${KV_MAJOR}.${KV_MINOR}" ]; then
	KERNEL_CONFIG="${CONFIG_DIR}/kernel-config-${KV_MAJOR}.${KV_MINOR}"
	
    elif [ -f "${CONFIG_DIR}/kernel-config" ]; then
	KERNEL_CONFIG="${CONFIG_DIR}/kernel-config"
	
    else
	die 'Error: No kernel .config specified, or file not found!'
    fi
}

kbuild_enabled() {
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then 
		return 0
	else
		return 1
	fi
}

setup_kernel_args() {
	local KNAME
    KERNEL_ARGS=""
	# Override the default arch being built
	[ -n "$(profile_get_key arch)" ] && KERNEL_ARGS="${KERNEL_ARGS} ARCH=$(profile_get_key kernel-arch)"

	#if [ "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	#then
	#	if [ "$(profile_get_key arch-override)" == "um" \
	#		-o "$(profile_get_key arch-override)" == "xen0" \
	#		-o "$(profile_get_key arch-override)" == "xenU" ]
	#	then
	#		die "Compiling for ARCH=$(profile_get_key arch-override) requires kbuild_output to differ from the kernel-tree"
	#	fi
	#else
	#	KERNEL_ARGS="${KERNEL_ARGS} KBUILD_OUTPUT=$(profile_get_key kbuild-output)"		
	#fi
	#KERNEL_ARGS="${KERNEL_ARGS} KBUILD_OUTPUT=$(profile_get_key kbuild-output)"		
    
    if [ "$(profile_get_key kbuild-output)" != "$(profile_get_key kernel-tree)" ]
    then
        KERNEL_ARGS="${KERNEL_ARGS} KBUILD_OUTPUT=$(profile_get_key kbuild-output)"
    fi
	
    # Kernel cross compiling support
	if [ -n "$(profile_get_key kernel-cross-compile)" ]
	then
		KERNEL_ARGS="${KERNEL_ARGS} CROSS_COMPILE=$(profile_get_key kernel-cross-compile)-"
	fi

	# Override the localversion via the cmdline... 
	# all localversion vars are ignored
	# KNAME="$(profile_get_key kernel-name)"
	# ARGS="${ARGS} LOCALVERSION=-${KNAME}-${ARCH}"
}
