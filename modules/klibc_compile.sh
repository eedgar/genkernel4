# Used by the klibc module which defines KLCC to point to the klcc binary
# for usage by other modules.
logicTrue $(profile_get_key internal-uclibc) && require gcc

#if [ "$(profile_get_key arch-override)" == "um" -o "$(profile_get_key arch-override)" == "xen0" \
#     -o "$(profile_get_key arch-override)" == "xenU" ]
#then
#	require kernel_config_i386_stub
#else
#	require kernel_config
#fi
require kernel_config

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/klibc-1.1.1.tar.gz"

klibc_compile::() {
	local KLIBC_DIR="klibc-${KLIBC_VER}" KLIBC_SRCTAR="${SRCPKG_DIR}/klibc-1.1.1.tar.gz"
	local ARGS

	cd "${TEMP}"
	rm -rf "${KLIBC_DIR}" klibc-build-${KLIBC_VER}
	[ ! -f "${KLIBC_SRCTAR}" ] && die "Could not find klibc tarball: ${KLIBC_SRCTAR}"
	unpack "${KLIBC_SRCTAR}" || die 'Could not extract klibc tarball'
	[ ! -d "${KLIBC_DIR}" ] && die "klibc tarball ${KLIBC_SRCTAR} is invalid"
	cd "${KLIBC_DIR}"

	# Don't install to "//lib" fix
	sed -e 's:$(INSTALLROOT)/$(SHLIBDIR):$(INSTALLROOT)$(INSTALLDIR)/$(CROSS)lib:' -i klibc/Makefile
	
	if [ -f ${FIXES_FILES_DIR}/byteswap.h -a "${KLIBC_VER}" == '1.1.1' ]
	then
		print_info 1 '>> Inserting byteswap.h'
		cp "${FIXES_FILES_DIR}/byteswap.h" "include/"
	fi

	print_info 1 'klibc: >> Compiling...'
	echo "The kernel tree is set to $(profile_get_key kernel-tree)"

	ln -snf "$(profile_get_key kernel-tree)" linux || die "Could not link to $(profile_get_key kernel-tree)"
	sed -i MCONFIG -e "s|prefix      =.*|prefix      = ${TEMP}/klibc-build-${KLIBC_VER}|g" # Set the build directory
	sed -i Makefile -e 's|$(INSTALLDIR)/$(KCROSS)bin|$(INSTALLDIR)/bin|g' # Set the build directory
	sed -i Makefile -e 's|$(INSTALLDIR)/$(KCROSS)lib|$(INSTALLDIR)/lib|g' # Set the build directory
	sed -i Makefile -e 's|$(INSTALLDIR)/$(KCROSS)include|$(INSTALLDIR)/include|g' # Set the build directory
	sed -i Makefile -e 's|$(INSTALLROOT)$(INSTALLDIR)/$(CROSS)include/$$d|$(INSTALLROOT)$(INSTALLDIR)/include/$$d|g' # Set the build directory

	if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
	then
		if [ "$(profile_get_key arch-override)" == "um" -o "$(profile_get_key arch-override)" == "xen0" \
		     -o "$(profile_get_key arch-override)" == "xenU" ]
		then
			echo "KRNLOBJ = ${TEMP}/genkernel-kernel-$(profile_get_key arch-override)-i386" >> MCONFIG
		else
			echo "KRNLOBJ = $(profile_get_key kbuild-output)" >> MCONFIG
		fi
	fi
	
	# PPC fixup for 2.6.14+
	if kernel_is ge 2 6 14
	then
		if [ "${ARCH}" = 'ppc' -o "${ARCH}" = 'ppc64' ]
      	then
			echo 'INCLUDE += -I$(KRNLSRC)/arch/$(ARCH)/include' >> MCONFIG
		fi
	fi

	# turn on/off the cross compiler
	if [ -n "$(profile_get_key utils-cross-compile)" ]
	then
		sed -i MCONFIG -e "s|CROSS   = |CROSS = $(profile_get_key utils-cross-compile)|g"
		# Workaround for makefile that doesnt set CROSS consistently
		sed -i Makefile -e "s|\$(CROSS)klibc.config|klibc.config|g"
		sed -i Makefile -e "s|\$(KCROSS)klcc|klcc|g"
		sed -i Makefile -e "s|\$(CROSS)klcc|klcc|g"
	fi

	if [ "${ARCH}" = 'um' -o "${ARCH}" = 'xen0' -o "${ARCH}" = 'xenU' -o "${ARCH}" = 'x86' ]
	then
		compile_generic ARCH=i386 
	else
		compile_generic
	fi

	compile_generic install

	cd ${TEMP}
	genkernel_generate_package "klibc-${KLIBC_VER}" klibc-build-${KLIBC_VER}
	rm -rf "${KLIBC_DIR}" klibc-build-${KLIBC_VER}
}
