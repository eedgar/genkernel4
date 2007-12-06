# Output: binpackage { / -> "busybox" }
# Placement: TBD
logicTrue $(profile_get_key internal-uclibc) && require gcc

# Check that these files exist"
files_register "${SRCPKG_DIR}/busybox-${BUSYBOX_VER}.tar.bz2"

busybox_compile::()
{
	local	BUSYBOX_SRCTAR="${SRCPKG_DIR}/busybox-${BUSYBOX_VER}.tar.bz2" BUSYBOX_DIR="busybox-${BUSYBOX_VER}" \
		BUSYBOX_CONFIG
	[ -f "${BUSYBOX_SRCTAR}" ] || die "Could not find busybox source tarball: ${BUSYBOX_SRCTAR}!"

	if [ -n "$(profile_get_key busybox-config)" ]
	then
		BUSYBOX_CONFIG="$(profile_get_key busybox-config)"
	elif [ -f "${TEMP}/busybox-custom-${BUSYBOX_VER}.config" ]
	then
		BUSYBOX_CONFIG="${TEMP}/busybox-custom-${BUSYBOX_VER}.config"
	elif [ -f "/etc/kernels/busybox-custom-${BUSYBOX_VER}.config" ]
	then
		BUSYBOX_CONFIG="/etc/kernels/busybox-custom-${BUSYBOX_VER}.config"
	elif [ -f "${CONFIG_DIR}/busybox.config" ]
	then
		BUSYBOX_CONFIG="${CONFIG_DIR}/busybox.config"
	elif [ -f "${CONFIG_GENERIC_DIR}/busybox.config" ]
	then
		BUSYBOX_CONFIG="${CONFIG_GENERIC_DIR}/busybox.config"
	elif [ "${DEFAULT_BUSYBOX_CONFIG}" != "" -a -f "${DEFAULT_BUSYBOX_CONFIG}" ]
	then
		BUSYBOX_CONFIG="${DEFAULT_BUSYBOX_CONFIG}"
	else
		die 'Error: No busybox .config specified, or file not found!'
	fi
	cd "${TEMP}"
	rm -rf ${BUSYBOX_DIR} > /dev/null
	unpack ${BUSYBOX_SRCTAR} || die 'Could not extract busybox source tarball!'
	[ -d "${BUSYBOX_DIR}" ] || die 'Busybox directory ${BUSYBOX_DIR} is invalid!'
	cd "${BUSYBOX_DIR}" > /dev/null
	gen_patch ${FIXES_PATCHES_DIR}/busybox/${BUSYBOX_VER} .
	cp "${BUSYBOX_CONFIG}" .config
   
	yes '' 2>/dev/null | compile_generic oldconfig
	print_info 1 'busybox: >> Configuring...'
	if logicTrue $(profile_get_key busybox-menuconfig)
	then
		print_info 1 "${PRINT_PREFIX}>> Running busybox menuconfig..."
		compile_busybox runtask menuconfig
		[ "$?" ] || die 'Error: busybox menuconfig failed!'
		
		if [ -w /etc/kernels ]
		then
			profile_set_key busybox-config-destination-path "/etc/kernels"
		else
			print_info 1 ">> Busybox config install path: ${BOLD}/etc/kernels ${NORMAL}is not writeable attempting to use ${TEMP}/genkernel-output"
			if [ ! -w ${TEMP} ]
			then
				die "Could not write to ${TEMP}/genkernel-output."
			else
				mkdir -p ${TEMP}/genkernel-output || die "Could not make ${TEMP}/genkernel-output."
				profile_set_key busybox-config-destination-path "${TEMP}/genkernel-output"
			fi
		fi
		mkdir -p "$(profile_get_key busybox-config-destination-path)"
		cp .config "$(profile_get_key busybox-config-destination-path)/busybox-custom-${BUSYBOX_VER}.config"	
		print_info 1 "Custom busybox config file saved to $(profile_get_key busybox-config-destination-path)/busybox-custom-${BUSYBOX_VER}.config"

	fi
	
	# TODO Add busybox config changing support
	config_set ".config" "CONFIG_FEATURE_INSTALLER" "y"

	# turn on/off the cross compiler
	if [ "$(profile_get_key utils-cross-compile)" != "" ]
	then
		print_info 1 "Setting cross compiler to $(profile_get_key utils-cross-compile)"
        TARGET=$(profile_get_key utils-cross-compile)
		config_set ".config" "USING_CROSS_COMPILER" "y"
		config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key utils-cross-compile)-"
	else
        TARGET=$(gcc -dumpmachine)
		config_unset ".config" "USING_CROSS_COMPILER"
		config_unset ".config" "CROSS_COMPILER_PREFIX"
	fi
	
	yes '' 2>/dev/null | compile_generic oldconfig
    # less .config
	print_info 1 'busybox: >> Compiling...'
	compile_generic all
    # No need to strip output the Makefile already does it.

	[ -f "busybox" ] || die 'Busybox executable does not exist!'
	
	[ -e "${TEMP}/busybox-compile" ] && rm -r ${TEMP}/busybox-compile
	mkdir ${TEMP}/busybox-compile
	
	cp busybox ${BUSYBOX_CONFIG} ${TEMP}/busybox-compile
	cd ${TEMP}/busybox-compile
	genkernel_generate_package "busybox-${BUSYBOX_VER}" "."
    
	cd "${TEMP}"
	rm -rf "${TEMP}/busybox-compile" > /dev/null
	rm -rf "${BUSYBOX_DIR}" > /dev/null
}
