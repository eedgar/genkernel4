#!/bin/bash

# genkernel-modular/core/gen_coreFunctions.sh
# -- Various core subroutines

# Copyright: 2006 plasmaroo@gentoo,org, rocket@gentoo.org
# License: GPLv2

die() {
	dump_trace
    if [ -w ${DEBUGFILE} ]
    then
      echo "${BAD}Error${NORMAL}: $1" |tee -a ${DEBUGFILE}
    else
      echo "${BAD}Error${NORMAL}: $1"
    fi
	exit 1
}

set_color() {
    if logicTrue $(profile_get_key usecolor)
    then
        GOOD=$'\e[32;01m'
        WARN=$'\e[33;01m'
        BAD=$'\e[31;01m'
        NORMAL=$'\e[0m'
        BOLD=$'\e[0;01m'
        UNDER=$'\e[4m'
    else
        echo '[ Turning color off ]'
        GOOD=''
        WARN=''
        BAD=''
        NORMAL=''
        BOLD=''
        UNDER=''
    fi
}

dump_debugcache() {
	TODEBUGCACHE=false
	echo "${DEBUGCACHE}" >> ${DEBUGFILE}
}

trap_cleanup(){
    # Call exit code of 1 for failure
    cleanup
    exit 1
}

cleanup(){
    if [ -n "$TEMP" -a -d "$TEMP" ]; then
	rm -rf "$TEMP"
    fi

    if logicTrue ${POSTCLEAR}
    then
        echo
        print_info 1 'RUNNING FINAL CACHE/TMP CLEANUP'
        print_info 1 "CACHE_DIR: ${CACHE_DIR}"
        CLEAR_CACHE_DIR='yes'
        setup_cache_dir
        echo
        print_info 1 "CACHE_CPIO_DIR: ${CACHE_CPIO_DIR}"
        CLEAR_CPIO_CACHE='yes'
        clear_cpio_dir
        echo
        print_info 1 "TMPDIR: ${TMPDIR}"
        clear_tmpdir
    fi
}

# print_info(debuglevel, print [, newline [, prefixline [, forcefile ] ] ])
print_info() {
	local NEWLINE=1
	local FORCEFILE=0
	local PREFIXLINE=1
	local SCRPRINT=0
	local STR=''

	# Not enough args
	if [ "$#" -lt '2' ] ; then return 1; fi

	# Check if we want a newline since the param is specified
	if [ "$#" -gt '2' ]
	then
		if logicTrue "$3"
		then
			NEWLINE='1';
		else
			NEWLINE='0';
		fi
	fi

	# Check prefix
	if [ "$#" -gt '3' ]
	then
		if logicTrue "$4"
		then
			PREFIXLINE='1'
		else
			PREFIXLINE='0'
		fi
	fi

	# IF 5 OR MORE ARGS, CHECK IF WE WANT TO FORCE OUTPUT TO DEBUG
	# FILE EVEN IF IT DOESN'T MEET THE MINIMUM DEBUG REQS
	if [ "$#" -gt '4' ]
	then
		if logicTrue "$5"
		then
			FORCEFILE='1'
		else
			FORCEFILE='0'
		fi
	fi

	# PRINT TO SCREEN ONLY IF PASSED DEBUGLEVEL IS HIGHER THAN
	# OR EQUAL TO SET DEBUG LEVEL
    if [ -n "$(profile_get_key debuglevel)" ]
    then
	    if [ "$1" -lt "$(profile_get_key debuglevel)" -o "$1" -eq "$(profile_get_key debuglevel)" ]
	    then
		    SCRPRINT='1'
	    fi
    else
		SCRPRINT='0'
    fi

	# RETURN IF NOT OUTPUTTING ANYWHERE
	if [ "${SCRPRINT}" != '1' -a "${FORCEFILE}" != '1' ]
	then
		return 0
	fi

	# STRUCTURE DATA TO BE OUTPUT TO SCREEN, AND OUTPUT IT
	if [ "${SCRPRINT}" -eq '1' ]
	then
		if [ "${PREFIXLINE}" = '1' ]
		then
			STR="${GOOD}*${NORMAL} ${2}"
		else
			STR="${2}"
		fi

		if [ "${NEWLINE}" -eq '0' ]
		then
			echo -ne "${STR}"
		else
			echo "${STR}"
		fi
	fi

	# STRUCTURE DATA TO BE OUTPUT TO FILE, AND OUTPUT IT
	if [ "${SCRPRINT}" -eq '1' -o "${FORCEFILE}" -eq '1' ]
	then
		STRR=${2//${WARN}/}
		STRR=${STRR//${BAD}/}
		STRR=${STRR//${BOLD}/}
		STRR=${STRR//${NORMAL}/}

		if [ "${PREFIXLINE}" = '1' ]
		then
			STR="* ${STRR}"
		else
			STR="${STRR}"
		fi

		if [ "${NEWLINE}" = '0' ]
		then
			if logicTrue "${TODEBUGCACHE}" ; then
				DEBUGCACHE="${DEBUGCACHE}${STR}"
			else
				echo -ne "${STR}" >> ${DEBUGFILE}
			fi	
		else
			if logicTrue "${TODEBUGCACHE}" ; then
				DEBUGCACHE="${DEBUGCACHE}${STR}"$'\n'
			else
				echo "${STR}" >> ${DEBUGFILE}
                #if [ -w ${DEBUGFILE} ]
                #then
				#    echo "${STR}" >> ${DEBUGFILE}
                #else
				#    echo "${STR}"
                #fi
			fi
		fi
	fi

	return 0
}

print_error()
{
	GOOD=${BAD} print_info "$@"
}

print_warning()
{
	GOOD=${WARN} print_info "$@"
}

# var_replace(var_name, var_value, string)
# $1 = variable name
# $2 = variable value
# $3 = string

var_replace()
{
  # Escape '\' and '.' in $2 to make it safe to use
  # in the later sed expression
  local SAFE_VAR
  SAFE_VAR=`echo "${2}" | sed -e 's/\([\/\.]\)/\\\\\\1/g'`
  
  echo "${3}" | sed -e "s/%%${1}%%/${SAFE_VAR}/g" -
}

arch_replace() {
  var_replace "ARCH" "${ARCH}" "${1}"
}

kv_replace() {
  var_replace "KV" "${KV}" "${1}"
}

cache_replace() {
  var_replace "CACHE" "${CACHE_DIR}" "${1}"
}

clear_log() {
        # Override with env variable, if non-zero
    	[ -n "${DEBUGFILE}" ] && profile_set_key debugfile "${DEBUGFILE}"

	# If the profile is mute on the destination file, or the destination
	# is not writable, use mktemp.
	[ -z "$(profile_get_key debugfile)" ] && DEBUGFILE="$(mktemp -t genkernel.log.XXXXXXXXXX)"
	[ ! -w "$(profile_get_key debugfile)" ]  && DEBUGFILE="$(mktemp -t genkernel.log.XXXXXXXXXX)"

	profile_set_key debugfile "${DEBUGFILE}"
	print_info 1 ">> Debug log: ${BOLD}$(profile_get_key debugfile) ${NORMAL}"
}

die_debugged() {
	dump_debugcache

	if [ "$#" -gt '0' ]
	then
		print_error 1 "ERROR: ${1}"
	fi
	echo
	print_info 1 "-- Grepping log... --"
	echo

	if logicTrue ${USECOLOR}
	then
		GREP_COLOR='1' grep -B5 -E --colour=always "([Ww][Aa][Rr][Nn][Ii][Nn][Gg]|[Ee][Rr][Rr][Oo][Rr][ :,!]|[Ff][Aa][Ii][Ll][Ee]?[Dd]?)" ${DEBUGFILE}
	else
		grep -B5 -E "([Ww][Aa][Rr][Nn][Ii][Nn][Gg]|[Ee][Rr][Rr][Oo][Rr][ :,!]|[Ff][Aa][Ii][Ll][Ee]?[Dd]?)" ${DEBUGFILE}
	fi
	echo
	print_info 1 "-- End log... --"
	echo
	print_info 1 "Please consult ${DEBUGFILE} for more information and any"
	print_info 1 "errors that were reported above."
	echo
	print_info 1 "Report any genkernel bugs to www.genkernel.org. Please include"
	print_info 1 "as much information as you can in your bug report; attaching"
	print_info 1 "${DEBUGFILE} so that your issue can be dealt with effectively."
	print_info 1 ''
	print_info 1 'Please do *not* report compilation failures as genkernel bugs!'
	print_info 1 ''

	# Cleanup temp dirs and caches if requested
	cleanup
  	exit 1
}
setup_cross_compile()
{
    if [ -n "$(profile_get_key cross-compile)" ]
    then
        if [ -z "$(profile_get_key utils-cross-compile)" ]
        then
            profile_set_key utils-cross-compile $(profile_get_key cross-compile)
        fi
        if [ -z "$(profile_get_key kernel-cross-compile)" ]
        then
            profile_set_key kernel-cross-compile $(profile_get_key cross-compile)
        fi
    fi
    print_info 3 "cross-compile: $(profile_get_key cross-compile)"
    print_info 3 "kernel-cross-compile: $(profile_get_key kernel-cross-compile)"
    print_info 3 "utils-cross-compile: $(profile_get_key utils-cross-compile)"

}

setup_arch()
{
    if [ -n "$(profile_get_key arch)" ]
    then
        if [ -z "$(profile_get_key utils-arch)" ]
        then
            profile_set_key utils-arch $(profile_get_key arch)
        fi
        if [ -z "$(profile_get_key kernel-arch)" ]
        then
            profile_set_key kernel-arch $(profile_get_key arch)
        fi
    fi
    print_info 3 "arch: $(profile_get_key arch)"
    print_info 3 "kernel-arch: $(profile_get_key kernel-arch)"
    print_info 3 "utils-arch: $(profile_get_key utils-arch)"
}

setup_cache_dir()
{
	[ ! -d "${CACHE_DIR}" ] && mkdir -p "${CACHE_DIR}"

	if [ "${CLEAR_CACHE_DIR}" == 'yes' ]
	then
		print_info 1 "Clearing cache dir contents from ${CACHE_DIR}"
		CACHE_DIR_CONTENTS=`ls ${CACHE_DIR}|grep -v CVS|grep -v cpio|grep -v README`

		for i in ${CACHE_DIR_CONTENTS}
		do
			print_info 1 "	 >> removing ${i}"
			rm ${CACHE_DIR}/${i}
		done
	fi
}

clear_tmpdir()
{
	if ! logicTrue ${CMD_NOINSTALL}
	then
		TMPDIR_CONTENTS=`ls ${TMPDIR}`
		print_info 1 "Removing tmp dir contents"
		for i in ${TMPDIR_CONTENTS}
		do
			print_info 1 "	 >> Removing ${i}"
			rm ${TMPDIR}/${i}
		done
	fi
}

# subtract_from_list item list
subtract_from_list() {
	local test=${1} item output
	shift

	myArgs="$*"
	myArgs=" ${myArgs} " # Pad with whitespace for removal
	myArgs="${myArgs/ ${test} /}"
	myArgs="${myArgs# }"
	myArgs="${myArgs% }"
	echo "${myArgs}"

	#for item in $@; do
	#	[[ "${item}" != "${test}" ]] && output="${output} ${item}"
	#done
	#echo "${output}"

}

# has test list
# Return true if list contains test
has() {
	# From eselect
	local test=${1} item
	shift
	local items=$@

	[[ $items =~ ^$test$ ]] && return 0
	[[ $items =~ ^$test\ .* ]] && return 0
	[[ $items =~ .*\ $test\ .* ]] && return 0
	[[ $items =~ .*\ $test$ ]] && return 0
	#echo "has \"$test\" \"$items\""
	#for item in $@; do
	#	
	#	[[ ${item} == ${test} ]] && return 0
	#done
	return 1
}

logicTrue() {
	[ "$*" = 'true' ] && return 0
	[ "$*" = '1' ] && return 0
	return 1
}

## Compilation functions

compile_generic() {
	local RET myAction

	if [ "$1" == 'runtask' ]
	then
		myAction="$1"
		shift
	else
		myAction='other'
	fi

	OPTS=$@
	if [ "${myAction}" == 'runtask' ]
	then
        MAKEOPTS=$(profile_get_key makeopts)
		print_info 2 "COMMAND: ${MAKE} ${OPTS}" 1 0 1
		make "$@" 
	else
		print_info 2 "COMMAND: make $(profile_get_key makeopts) ${OPTS}" 1 0 1
		if [ "$(profile_get_key debuglevel)" -gt "1" ]
		then
			# Output to stdout and debugfile
			make $(profile_get_key makeopts) "$@" 2>&1 | tee -a ${DEBUGFILE}
			RET=${PIPESTATUS[0]}
	        [ "${RET}" -eq '0' ] || die "Failed to compile ..."
		else
			# Output to debugfile only
			make $(profile_get_key makeopts) "$@" >> ${DEBUGFILE} 2>&1
			RET=$?
	        [ "${RET}" -eq '0' ] || die "Failed to compile ..."
		fi
	fi
}

configure_generic() {
	local RET
	print_info 2 "COMMAND: configure ${OPTS}" 1 0 1
	if [ "$(profile_get_key debuglevel)" -gt "1" ]
	then
		# Output to stdout and debugfile
		./configure "$@" 2>&1 | tee -a ${DEBUGFILE}
		RET=${PIPESTATUS[0]}
	else
		# Output to debugfile only
		./configure "$@" >> ${DEBUGFILE} 2>&1
		RET=$?
	fi
	[ "${RET}" -eq '0' ] || die "Failed to configure ..."
}

## Genkernel functions

genkernel_print_header() {
	# print the header if the profile-dump wasnt specified on the cmdline
	if [ -z "$(profile_get_key profile-dump user)" ]
	then
		NORMAL=${GOOD} print_info 1 "genkernel version ${GK_V}${NORMAL} (www.genkernel.org)"
        if [ -n "${Options}" ]
        then
		    print_info 1 "Running with options: ${Options}"
        fi
		echo
	fi
}
determine_profile() {
	local myProfile=$(profile_get_key profile user)
	
	ARCH=$(uname -m)
	case "${ARCH}" in
		i?86)
			ARCH='x86'
	        profile_set_key "arch" "i386" "system"
		;;
		mips64)
			ARCH='mips'
	        profile_set_key "arch" "mips" "system"
		;;
		*)
	        profile_set_key "arch" "${ARCH}" "system"
		;;
    esac
    
    if [ "${myProfile}" != '' ]
	then
	    profile_set_key "profile" "${myProfile}"
    else
        # This is the default profile to use.
	    profile_set_key "profile" "${ARCH}"
    fi
}

print_list()
{
	local x
	for x in ${*}
	do
		echo ${x}
	done
}

external_initramfs() {
	
	# If we are building an internal initramfs then it is not external
	if logicTrue $(internal_initramfs)
	then
		echo "false"
	elif logicTrue $(profile_get_key initramfs)
	then
		echo "true"
	else	
		echo "false"
	fi
}

internal_initramfs() {
	if logicTrue $(profile_get_key internal-initramfs) && logicTrue $(profile_get_key initramfs)
	then
		echo "true"
	else
		echo "false"
	fi
}

initramfs() {
	
	if logicTrue $(internal_initramfs) 
	then
		echo "true" 
	elif logicTrue $(external_initramfs) 
	then
		echo "true" 
	else
		echo "false"
	fi
}

config_set_string() {
    # TODO need to check for null entry entirely
    sed -i ${1} -e "s|#\? \?${2} is.*|${2}=\"${3}\"|g"
    sed -i ${1} -e "s|${2}=.*|${2}=\"${3}\"|g"
    if config_is_not_set ${1} ${2}
    then
	print_info 1 "subconfig: Forced setting ${2}=${3} on ${1}"
        echo "${2}=\"${3}\"" >>  ${1}
#    else
#	echo "The config val was set"
    fi
}

config_set() {
    # TODO need to check for null entry entirely
    sed -i ${1} -e "s|#\? \?${2} is.*|${2}=${3}|g"
    sed -i ${1} -e "s|${2}=.*|${2}=${3}|g"
    if config_is_not_set ${1} ${2}
    then
	print_info 1 "subconfig: Forced setting ${2}=${3} on ${1}"
        echo "${2}=${3}" >>  ${1}
#   else
#	echo "The config val was set"
    fi
}

config_unset() {
    sed -i ${1} -e "s/${2}=.*/# ${2} is not set/g"
}

config_is_set() {
    local RET_STR
    RET_STR=$(grep ${2}= ${1})
    [ "${RET_STR%%=*}=" == "$2=" ] && return 0 || return 1
}

config_is_not_set() {
    local RET_STR
    RET_STR=$(grep ${2} ${1})
    [ "${RET_STR}" == "# $2 is not set" ] && return 0
    [ "${RET_STR}" == "" ] && return 0
    return 1
}

gen_patch() {
	patchdir=$1
	targetdir=$2	

	if [ -d $patchdir ]
	then	
	    for i in $(find ${patchdir} -type f -iname \*.patch|sort)
	    do
    		case "$i" in
    		    *.gz)
    			type="gzip"; uncomp="gunzip -dc";
			;;
    		    *.bz)
    			type="bzip"; uncomp="bunzip -dc";
			;;
    		    *.bz2)
    			type="bzip2"; uncomp="bunzip2 -dc";
			;;
    		    *.zip)
    			type="zip"; uncomp="unzip -d";
			;;
    		    *.Z)
    			type="compress"; uncomp="uncompress -c";
			;;
    		    *)
    			type="plaintext"; uncomp="cat";
			;;
    		esac

		print_info 1 "patch-o-matic: ${i}"
		    if [ "$(profile_get_key debuglevel)" -gt "1" ]
		    then
    		    ${uncomp} ${i} | patch -p1 -E -d ${targetdir} 2>&1 | tee -a ${DEBUGFILE}
                RET=${PIPESTATUS[1]}
            else
    		    ${uncomp} ${i} | patch -p1 -s -E -d ${targetdir} 2>&1 | tee -a ${DEBUGFILE}
                RET=${PIPESTATUS[1]}
            fi
    		if [ $RET != 0 ] ; then
        	    die "Patch failed! Please fix $i!"
    		fi
	    done
	fi
}

# Originally From Portage
# usage- first arg is the number of funcs on the stack to ignore.
# defaults to 1 (ignoring dump_trace)
dump_trace() {
	local funcname="" sourcefile="" lineno="" p n e s="yes"
	declare -i strip=1

	if [[ -n $1 ]]; then
		strip=$(( $1 ))
	fi
	
	print_info 1 "Call stack:"
	for (( n = ${#FUNCNAME[@]} - 1, p = ${#BASH_ARGV[@]} ; n > $strip ; n-- )) ; do
		funcname=${FUNCNAME[${n} - 1]}
		sourcefile=$(basename ${BASH_SOURCE[${n}]})
		lineno=${BASH_LINENO[${n} - 1]}
		print_info 1 "  ${sourcefile}, line ${lineno}:   Called ${funcname}${args:+ ${args}}"
	done
}
