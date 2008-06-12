require kernel_config db
logicTrue $(profile_get_key internal-uclibc) && require gcc

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/open-iscsi-${OPENISCSI_VER}.tar.gz"

open_iscsi_tools_compile::()
{
	local OPENISCSI_SRCTAR="${SRCPKG_DIR}/open-iscsi-${OPENISCSI_VER}.tar.gz" 
	local OPENISCSI_DIR="open-iscsi-${OPENISCSI_VER}"
	[ -f "${OPENISCSI_SRCTAR}" ] || die "Could not find open-iscsi source tarball: ${OPENISCSI_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${OPENISCSI_DIR}"
	unpack "${OPENISCSI_SRCTAR}" || die "Failed to unpack open-iscsi sources!"
	[ ! -d "${OPENISCSI_DIR}" ] && die "open-iscsi directory ${OPENISCSI_DIR} invalid"

	cd "${OPENISCSI_DIR}"
	gen_patch ${FIXES_PATCHES_DIR}/open-iscsi/${OPENISCSI_VER} .
	
	# turn on/off the cross compiler
	#if [ -n "$(profile_get_key cross-compile)" ]
	#then
	#	ARGS="${ARGS} CC=$(profile_get_key cross-compile)gcc"
    #else
	#	[ -n "$(profile_get_key utils-cross-compile)" ] && \
	#		ARGS="${ARGS} CC=$(profile_get_key utils-cross-compile)gcc"
	#fi

    OPENISCSI_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
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
   # turn on/off the cross compiler
	if [ -n "$(profile_get_key utils-cross-compile)" ]
	then
		CC="$(profile_get_key utils-cross-compile)-gcc"
        # sysroot isysroot
	else
		CC="gcc"
	fi

	print_info 1 'open-iscsi-tools: >> Compiling...'
	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		compile_generic KSRC=$(profile_get_key kernel-tree) KBUILD_OUTPUT=$(profile_get_key kbuild-output) KARCH=ARCH=${OPENISCSI_TARGET_ARCH} OPTFLAGS="-static -I${DB_OUTPUT}/include -L${DB_OUTPUT}/lib -O2 -g" CC=${CC} -C usr
	else
		compile_generic KSRC=$(profile_get_key kernel-tree) KARCH=ARCH=${OPENISCSI_TARGET_ARCH} OPTFLAGS="-static -I${DB_OUTPUT}/include -L${DB_OUTPUT}/lib -O2 -g" CC=${CC} -C usr
	fi
	

    [ -e "${TEMP}/open-iscsi-tools" ] && rm -r ${TEMP}/open-iscsi-tools
    mkdir -p ${TEMP}/open-iscsi-tools

    compile_generic DESTDIR=${TEMP}/open-iscsi-tools install_programs
    compile_generic DESTDIR=${TEMP}/open-iscsi-tools install_etc
	cp usr/iscsistart ${TEMP}/open-iscsi-tools/usr/sbin    
	cd ${TEMP}/open-iscsi-tools

    genkernel_generate_package "open-iscsi-${OPENISCSI_VER}-tools" "."

    cd ${TEMP}

    rm -rf "${OPENISCSI_DIR}" > /dev/null
    rm -rf "${TEMP}/open-iscsi-tools" > /dev/null
}
