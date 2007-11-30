require gcc_stage1

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/uClibc-${UCLIBC_VER}.tar.bz2"

uclibc_stage2_compile::()
{
	local	UCLIBC_SRCTAR="${SRCPKG_DIR}/uClibc-${UCLIBC_VER}.tar.bz2" 
	local   UCLIBC_DIR="uClibc-${UCLIBC_VER}" 
	[ -f "${UCLIBC_SRCTAR}" ] || die "Could not find uclibc source tarball: ${UCLIBC_SRCTAR}!"

	cd "${CACHE_DIR}"
	rm -rf ${UCLIBC_DIR} > /dev/null
	unpack ${UCLIBC_SRCTAR} || die 'Could not extract uclibc source tarball!'
	[ -d "${UCLIBC_DIR}" ] || die 'uclibc directory ${UCLIBC_DIR} is invalid!'

	cd "${UCLIBC_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/uclibc/${UCLIBC_VER} .
   
	print_info 1 'uClibc: >> Configuring...'
	compile_generic defconfig

    UCLIBC_TARGET_ARCH=$(profile_get_key utils-arch)

	profile_set_key utils-cross-compile "${CACHE_DIR}/staging/bin/${UCLIBC_TARGET_ARCH}-linux-uclibc-"

    if [ -n "$(profile_get_key utils-cross-compile)" ]
	then
    	config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key utils-cross-compile)"
	else
    	config_unset ".config" "CROSS_COMPILER_PREFIX"
	fi

	# just handle the ones that can be big or little
	UCLIBC_TARGET_ENDIAN=$(echo ${UCLIBC_TARGET_ARCH} | sed \
        -e 's/armeb/BIG/' \
        -e 's/arm/LITTLE/' \
        -e 's/mipsel/LITTLE/' \
        -e 's/mips/BIG/' \
	)

	if [ "${UCLIBC_TARGET_ENDIAN}" != "BIG" -o "${UCLIBC_TARGET_ENDIAN}" != "LITTLE" ]
	then
		UCLIBC_TARGET_ENDIAN=""
	fi

	if [ "${UCLIBC_TARGET_ENDIAN}" == "LITTLE" ]
	then
		UCLIBC_NOT_TARGET_ENDIAN="BIG"
	else
		UCLIBC_NOT_TARGET_ENDIAN="LITTLE"
	fi


	config_set .config TARGET_${UCLIBC_TARGET_ARCH} "y"
	config_set_string .config TARGET_ARCH "${UCLIBC_TARGET_ARCH}"
	config_set .config UCLIBC_HAS_FULL_RPC "y"
	config_set_string .config KERNEL_SOURCE "${CACHE_DIR}/staging/usr/${UCLIBC_TARGET_ARCH}-linux-uclibc/usr/"
	for def in MALLOC_GLIBC_COMPAT DO_C99_MATH UCLIBC_HAS_{RPC,CTYPE_CHECKED,WCHAR,HEXADECIMAL_FLOATS,GLIBC_CUSTOM_PRINTF,FOPEN_EXCLUSIVE_MODE,GLIBC_CUSTOM_STREAMS,PRINTF_M_SPEC,FTW} ; do
		config_set .config ${def} "y"
	done
	
	if [ -n "${UCLIBC_TARGET_ENDIAN}" ]
	then
		config_set .config ARCH_${UCLIBC_TARGET_ENDIAN}_ENDIAN "y"
		config_set .config ARCH_${UCLIBC_NOT_TARGET_ENDIAN}_ENDIAN "n"
	fi

	yes '' 2>/dev/null | compile_generic oldconfig

	
	print_info 1 'uClibc: >> Compiling...'
	compile_generic prefix= devel_prefix=/ runtime_prefix=/ hostcc=gcc all
	compile_generic DEVEL_PREFIX="${CACHE_DIR}/staging/" RUNTIME_PREFIX="${CACHE_DIR}/staging/" install_runtime install_dev

	# Move includes so gcc can find them
	cp -r "${CACHE_DIR}/staging/include" "${CACHE_DIR}/staging/usr"
	mv "${CACHE_DIR}/staging/include" "${CACHE_DIR}/staging/${UCLIBC_TARGET_ARCH}-linux-uclibc"
	
	cd ${CACHE_DIR}/staging
	genkernel_generate_package "uClibc-stage2-${UCLIBC_VER}" "."

	cd "${CACHE_DIR}"
	rm -rf "${UCLIBC_DIR}" > /dev/null
	rm -rf "${CACHE_DIR}/staging" > /dev/null
}
