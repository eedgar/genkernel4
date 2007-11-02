require gcc_stage1

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/uClibc-${UCLIBC_VER}.tar.bz2"

uclibc_stage2_compile::()
{
	local	UCLIBC_SRCTAR="${SRCPKG_DIR}/uClibc-${UCLIBC_VER}.tar.bz2" 
	local   UCLIBC_DIR="uClibc-${UCLIBC_VER}" 
	[ -f "${UCLIBC_SRCTAR}" ] || die "Could not find uclibc source tarball: ${UCLIBC_SRCTAR}!"

	cd "${TEMP}"
	rm -rf ${UCLIBC_DIR} > /dev/null
	unpack ${UCLIBC_SRCTAR} || die 'Could not extract uclibc source tarball!'
	[ -d "${UCLIBC_DIR}" ] || die 'uclibc directory ${UCLIBC_DIR} is invalid!'

	cd "${UCLIBC_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/uclibc/${UCLIBC_VER} .
   
	print_info 1 'uClibc: >> Configuring...'
	compile_generic defconfig

    GCC_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
        -e 's/x86$/i386/' \
        -e 's/i.86$/i386/' \
        -e 's/sparc.*/sparc/' \
        -e 's/arm.*/arm/g' \
        -e 's/m68k.*/m68k/' \
        -e 's/ppc/powerpc/g' \
        -e 's/v850.*/v850/g' \
        -e 's/sh[234].*/sh/' \
        -e 's/mips.*/mips/' \
        -e 's/mipsel.*/mips/' \
        -e 's/cris.*/cris/' \
        -e 's/nios2.*/nios2/' \
    )

	profile_set_key utils-cross-compile "${TEMP}/staging/bin/${GCC_TARGET_ARCH}-linux-uclibc-"

	# turn on/off the cross compiler
	if [ -n "$(profile_get_key cross-compile)" ]
	then
    	config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key cross-compile)"
    elif [ -n "$(profile_get_key utils-cross-compile)" ]
	then
    	config_set_string ".config" "CROSS_COMPILER_PREFIX" "$(profile_get_key utils-cross-compile)"
	else
    	config_unset ".config" "CROSS_COMPILER_PREFIX"
	fi

	UCLIBC_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
        -e 's/x86/i386/' \
        -e 's/i.86/i386/' \
        -e 's/sparc.*/sparc/' \
        -e 's/arm.*/arm/g' \
        -e 's/m68k.*/m68k/' \
        -e 's/ppc/powerpc/g' \
        -e 's/v850.*/v850/g' \
        -e 's/sh[234].*/sh/' \
        -e 's/mips.*/mips/' \
        -e 's/mipsel.*/mips/' \
        -e 's/cris.*/cris/' \
        -e 's/nios2.*/nios2/' \
		)

	# just handle the ones that can be big or little
	UCLIBC_TARGET_ENDIAN=$(echo ${ARCH} | sed \
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
	config_set_string .config KERNEL_SOURCE "${TEMP}/staging/usr/${UCLIBC_TARGET_ARCH}-linux-uclibc/usr/"
	for def in MALLOC_GLIBC_COMPAT DO_C99_MATH UCLIBC_HAS_{RPC,CTYPE_CHECKED,WCHAR,HEXADECIMAL_FLOATS,GLIBC_CUSTOM_PRINTF,FOPEN_EXCLUSIVE_MODE,GLIBC_CUSTOM_STREAMS,PRINTF_M_SPEC,FTW} ; do
		config_set .config ${def} "y"
	done
	
	# If headers are a quickpkg of linux-headers then move them into the right place...
	if [ -e "${TEMP}/staging/usr/include" ]
	then
		mkdir "${TEMP}/staging/usr/${UCLIBC_TARGET_ARCH}-linux-uclibc/usr" -p
		mv "${TEMP}/staging/usr/include" "${TEMP}/staging/usr/${UCLIBC_TARGET_ARCH}-linux-uclibc/usr"
	fi

	if [ -n "${UCLIBC_TARGET_ENDIAN}" ]
	then
		config_set .config ARCH_${UCLIBC_TARGET_ENDIAN}_ENDIAN "y"
		config_set .config ARCH_${UCLIBC_NOT_TARGET_ENDIAN}_ENDIAN "n"
	fi

	yes '' 2>/dev/null | compile_generic oldconfig

	
	print_info 1 'uClibc: >> Compiling...'
	compile_generic prefix= devel_prefix=/ runtime_prefix=/ hostcc=gcc all
	compile_generic DEVEL_PREFIX="${TEMP}/staging/" RUNTIME_PREFIX="${TEMP}/staging/" install_runtime install_dev

	# Move includes so gcc can find them
	cp -r "${TEMP}/staging/include" "${TEMP}/staging/usr"
	mv "${TEMP}/staging/include" "${TEMP}/staging/${UCLIBC_TARGET_ARCH}-linux-uclibc"
	
	cd ${TEMP}/staging
	genkernel_generate_package "uClibc-stage2-${UCLIBC_VER}" "."

	cd "${TEMP}"
	rm -rf "${UCLIBC_DIR}" > /dev/null
	rm -rf "${TEMP}/staging" > /dev/null
}
