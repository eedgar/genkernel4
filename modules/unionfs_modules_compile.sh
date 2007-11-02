require kernel_config
#logicTrue $(profile_get_key internal-uclibc) && require gcc

# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/unionfs-${UNIONFS_VER}.tar.gz"

unionfs_modules_compile::()
{
	local UNIONFS_SRCTAR="${SRCPKG_DIR}/unionfs-${UNIONFS_VER}.tar.gz" UNIONFS_DIR="unionfs-${UNIONFS_VER}"	
	if kernel_config_is_not_set "MODULES"
	then
		print_info 1 ">> Modules not enabled in .config ... skipping unionfs compile"
	elif kernel_config_is_set "UNION_FS"
	then
		print_info 1 ">> unionfs enabled in kernel ... skipping unionfs compile"
	else
		# stolen from uclibc_compile.sh
		UNIONFS_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
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

		cd "${TEMP}"
		rm -rf ${UNIONFS_DIR} > /dev/null
		unpack ${UNIONFS_SRCTAR} || die 'Could not extract unionfs source tarball!'
		[ -d "${UNIONFS_DIR}" ] || die 'Unionfs directory ${UNIONFS_DIR} is invalid!'
		cd "${UNIONFS_DIR}" > /dev/null	
		gen_patch ${FIXES_PATCHES_DIR}/unionfs/${UNIONFS_VER} .
		
		echo "ARCH=${UNIONFS_TARGET_ARCH}" > fistdev.mk
		echo "PREFIX=${TEMP}/unionfs-build" >> fistdev.mk
		echo "EXTRAUCFLAGS=-static -I${E2FSPROGS_STAGING}/include -L${E2FSPROGS_STAGING}/lib" >> fistdev.mk
		echo "EXTRACFLAGS=-DUNIONFS_UNSUPPORTED" >> fistdev.mk

		if [ ! "$(profile_get_key kbuild-output)" == "$(profile_get_key kernel-tree)" ]
		then
			echo "KBUILD_OUTPUT=$(profile_get_key kbuild-output)" >> fistdev.mk
		fi

		# turn on/off the cross compiler
		if [ "$(profile_get_key utils-cross-compile)" != "" ]
		then
			echo "UTILS_CROSS_COMPILE=$(profile_get_key utils-cross-compile)-" >> fistdev.mk
    	fi
		if [ "$(profile_get_key kernel-cross-compile)" != "" ]
		then
			echo "KERNEL_CROSS_COMPILE=$(profile_get_key kernel-cross-compile)-" >> fistdev.mk
    	fi

		print_info 1 "Compiling unionfs kernel module"

		compile_generic unionfs.ko
		[ -e ${TEMP}/unionfs-output ] && rm -rf ${TEMP}/unionfs-output
		mkdir -p ${TEMP}/unionfs-output/sbin
		mkdir -p ${TEMP}/unionfs-output/lib/modules/${KV_FULL}/extra
		cp unionfs.ko ${TEMP}/unionfs-output/lib/modules/${KV_FULL}/extra

#		print_info 1 "Compiling unionfs utilities"

#		compile_generic utils

		#cp unionimap ${TEMP}/unionfs-output/sbin
#		cp unionctl ${TEMP}/unionfs-output/sbin
		#cp uniondbg ${TEMP}/unionfs-output/sbin
		#strip ${TEMP}/unionfs-output/sbin/unionimap
#		strip ${TEMP}/unionfs-output/sbin/unionctl
		#strip ${TEMP}/unionfs-output/sbin/uniondbg
		
		cd ${TEMP}/unionfs-output

		genkernel_generate_package "unionfs-${UNIONFS_VER}-modules-${KV_FULL}" "."
		#genkernel_generate_cpio_path "unionfs-${UNIONFS_VER}" .
		#initramfs_register_cpio "unionfs-${UNIONFS_VER}"

		

	fi
}
