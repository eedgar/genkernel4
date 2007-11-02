#!/bin/bash

# genkernel-modular/core/gen_processPackages.sh
# -- Core package processing routines

# Copyright: 2006 plasmaroo@gentoo,org, rocket@gentoo.org
# License: GPLv2

declare -a __INTERNAL__PKG__CALLBACK__S # Source
declare -a __INTERNAL__PKG__CALLBACK__D # Data

package_check_lookup() {
	local target callback

	for (( n = 0 ; n <= ${#__INTERNAL__PKG__CALLBACK__S[@]}; ++n )) ; do
		target=${__INTERNAL__PKG__CALLBACK__S[${n}]}
		callback=${__INTERNAL__PKG__CALLBACK__D[${n}]}

		[ "$1" = "${target}" ] && echo "${callback}" && return
	done
}

# target callback
package_check_register () {
	# Multiple callbacks can be registered on a package.

	for (( n = 0 ; n <= ${#__INTERNAL__PKG__CALLBACK__S[@]}; ++n )) ; do
		if [ "$1" = "${__INTERNAL__PKG__CALLBACK__S[${n}]}" ]
		then
			__INTERNAL__PKG__CALLBACK__D[${n}]="${__INTERNAL__PKG__CALLBACK__D[${n}]} $2"
			return
		fi
	done

	# No luck; add the entry...
	__INTERNAL__PKG__CALLBACK__S[${#__INTERNAL__PKG__CALLBACK__S[@]}]="$1"
	__INTERNAL__PKG__CALLBACK__D[${#__INTERNAL__PKG__CALLBACK__D[@]}]="$2"
}

genkernel_lookup_packages()
{
	local myPkg myCallbacks myCallbacksStatus
	for i in ${CACHE_DIR}/pkg_*.tar.bz2
	do
		[ "${i}" = "${CACHE_DIR}/pkg_*.tar.bz2" ] && break # No matches found
		__INTERNAL__PKG__CALLBACK__STATUS=false # Reset

		# Strip directory and extension
		myPkg=${i##*/}
		myPkg=${myPkg%.tar.bz2}

		# Check for callbacks
		for j in $(package_check_lookup ${myPkg})
		do
			$j			
		done

		# Provide, if things are good
		if [ "${__INTERNAL__PKG__CALLBACK__STATUS}" = "false" ]
		then
			provide "${myPkg}"
			# echo Registering ${myPkg}
		fi
	done

	unset __INTERNAL__PKG__CALLBACK__STATUS
}

genkernel_generate_cpio() {
	if [ -z "$2" ]
	then
		[ -e "${TEMP}/$1.cpio.gz" ] && rm "${TEMP}/$1.cpio.gz"
		cpio --quiet -o -H newc | gzip -9 > "${TEMP}/$1.cpio.gz"
	else
		[ -e "${TEMP}/$1.cpio" ] && rm "${TEMP}/$1.cpio"
		cpio --quiet -o -H newc > "${TEMP}/$1.cpio"
	fi
}

genkernel_extract_cpio() {
    [ -e "$1" ] || die "File to unpack not present: $1!"
	
	if [ -n "$2" ]
	then
		mypwd=$PWD
		cd $2
	fi

    case "$1" in
        *.cpio)
			false
        ;;
        *.cpio.gz)
			gzipped=true
        ;;
        *.cpio.bz2)
            bzipped=true
        ;;
        *)
            die "Unrecognized filetype to unpack: $1!"
        ;;
    esac

    print_info 1 "unpack cpio: Processing $(basename ${1})..."
	if $gzipped
	then
		cat $1 |gunzip|cpio -i --quiet || die "Failed to unpack $1!"
	elif $bzipped
	then
		cat $1 |bunzip2|cpio -i --quiet || die "Failed to unpack $1!"
	else
		cat $1 |cpio -i --quiet || die "Failed to unpack $1!"
	fi

	[ -n "$mypwd" ] && cd $mypwd
}

genkernel_generate_cpio_path() {
	find $2 -print | genkernel_generate_cpio "$1" "$3"
}

genkernel_generate_cpio_files() {
	local name=$1
	shift

	print_list $* | genkernel_generate_cpio "${name}"
}

genkernel_generate_package() {
	[ -e "${CACHE_DIR}/pkg_$1.tar.bz2" ] && rm "${CACHE_DIR}/pkg_$1.tar.bz2"
	tar cjf "${CACHE_DIR}/pkg_$1.tar.bz2" "$2" || die "Could not create binary cache for $1!"
}

genkernel_extract_package() {
	[ -e "${CACHE_DIR}/pkg_$1.tar.bz2" ] || die "Binary cache not present for $1!"
	if [ "$(profile_get_key debuglevel)" -gt "3" ]
	then
		tar jvxf "${CACHE_DIR}/pkg_$1.tar.bz2" || die "Could not extract binary cache for $1!"
	else
		tar jxf "${CACHE_DIR}/pkg_$1.tar.bz2" || die "Could not extract binary cache for $1!"
	fi
}

genkernel_convert_tar_to_cpio() {
	cd "${TEMP}"

	# Set up links, generate CPIO
	rm -rf "${TEMP}/$1-cpiogen"
	mkdir -p "${TEMP}/$1-cpiogen"
	cd "${TEMP}/$1-cpiogen"

	genkernel_extract_package "$1-$2"
	genkernel_generate_cpio_path "$1-$2" .
	initramfs_register_cpio "$1-$2"

	cd ${TEMP}
	rm -rf "${TEMP}/$1-cpiogen"
}

unpack()
{
	local tarFlags
	[ -e "$1" ] || die "File to unpack not present: $1!"

	case "$1" in
		*.tar.bz2)
			tarFlags='j'
		;;
		*.tgz|*.tar.gz)
			tarFlags='z'
		;;
		*.tar)
			false
		;;
		*)
			die "Unrecognized filetype to unpack: $1!"
		;;
	esac

	print_info 1 "unpack: Processing $1..."
	tar ${tarFlags}xpf "$1" || die "Failed to unpack $1!"
}
