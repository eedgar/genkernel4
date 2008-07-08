# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/buildroot-${BUILDROOT_VER}.tar.bz2"

buildroot_compile::()
{
	local BUILDROOT_SRCTAR="${SRCPKG_DIR}/buildroot-${BUILDROOT_VER}.tar.bz2"
	local BUILDROOT_DIR="buildroot"
	
    [ -f "${BUILDROOT_SRCTAR}" ] || die "Could not find buildroot source tarball: ${BUILDROOT_SRCTAR}!"

	cd "${CACHE_DIR}"
	#rm -rf ${BUILDROOT_DIR} >  /dev/null
	#unpack ${BUILDROOT_SRCTAR} || die 'Could not extract buildroot source tarball!'
	[ -d "${BUILDROOT_DIR}" ] || die 'Buildroot directory ${BUILDROOT_DIR} is invalid!'
	cd "${BUILDROOT_DIR}"
	#gen_patch ${FIXES_PATCHES_DIR}/buildroot/${BUILDROOT_VER} .
	print_info 1 'BUILDROOT: > Configuring...'
	compile_generic defconfig
	if [ "$(profile_get_key utils-arch)" == "x86_64" ]
	then
		print_info 1 'BUILDROOT: Compiling for x86_64, Nocona...'
		config_unset .config BR2_i386
		config_unset .config BR2_x86_i686
		config_set .config BR2_x86_64 y
		config_set .config BR2_x86_64_nocona y
		config_set .config BR2_ARCH x86_64
		config_set .config BR2_GCC_TARGET_TUNE nocona
		config_unset .config BR2_GCC_TARGET_ARCH

	fi
	config_set .config BR2_DL_DIR "${SRCPKG_DIR}"
	config_set .config BR2_LARGEFILE y
	config_set .config BR2_INET_IPV6 y
	config_set .config BR2_INET_RPC y
	config_set .config BR2_CCACHE y
	config_set .config BR2_PACKAGE_FLEX y
	config_set .config BR2_PACKAGE_FLEX_LIBFL y
	config_unset .config BR2_HOST_FAKEROOT
	config_set .config BR2_PACKAGE_LIBGMP y
	config_set .config BR2_PACKAGE_BRIDGE y
	config_set .config BR2_PACKAGE_DROPBEAR y
	#config_set .config BR2_PACKAGE_IPTABLES y
	config_set .config BR2_PACKAGE_NCFTP y
	config_set .config BR2_PACKAGE_NCFTP_GET y
	config_set .config BR2_PACKAGE_NCFTP_PUT y
	config_set .config BR2_PACKAGE_NCFTP_LS y
	config_set .config BR2_PACKAGE_NCFTP_BATCH y
	config_set .config BR2_PACKAGE_NETKITBASE y
	config_set .config BR2_PACKAGE_NFS_UTILS y
	config_set .config BR2_PACKAGE_NFS_UTILS_RPCDEBUG y
	config_set .config BR2_PACKAGE_NFS_UTILS_RPC_LOCKD y
	config_set .config BR2_PACKAGE_NFS_UTILS_RPC_RQUOTAD y
	config_set .config BR2_PACKAGE_OPENSSL y
	config_set .config BR2_PACKAGE_OPENVPN y
	#config_set .config BR2_PACKAGE_OPENSWAN y
	config_set .config BR2_PACKAGE_PORTMAP y
	config_set .config BR2_PACKAGE_PPPD y
	config_set .config BR2_PACKAGE_RP_PPPOE y
	config_set .config BR2_PACKAGE_PPTP_LINUX y
	config_set .config BR2_PACKAGE_VTUN y
	config_set .config BR2_PACKAGE_WIRELESS_TOOLS y
	config_set .config BR2_PACKAGE_DM y
	config_set .config BR2_PACKAGE_DMRAID y
	config_set .config BR2_PACKAGE_E2FSPROGS y
	config_set .config BR2_PACKAGE_E2FSPROGS_BADBLOCKS y
	config_set .config BR2_PACKAGE_E2FSPROGS_BLKID y
	config_set .config BR2_PACKAGE_E2FSPROGS_CHATTR y
	config_set .config BR2_PACKAGE_E2FSPROGS_DUMPE2FS y
	config_set .config BR2_PACKAGE_E2FSPROGS_E2FSCK y
	config_set .config BR2_PACKAGE_E2FSPROGS_E2LABEL y
	config_set .config BR2_PACKAGE_E2FSPROGS_FILEFRAG y
	config_set .config BR2_PACKAGE_E2FSPROGS_FINDFS y
	config_set .config BR2_PACKAGE_E2FSPROGS_FSCK y
	config_set .config BR2_PACKAGE_E2FSPROGS_LOGSAVE y
	config_set .config BR2_PACKAGE_E2FSPROGS_LSATTR y
	config_set .config BR2_PACKAGE_E2FSPROGS_MKE2FS y
	config_set .config BR2_PACKAGE_E2FSPROGS_MKLOSTFOUND y
	config_set .config BR2_PACKAGE_E2FSPROGS_TUNE2FS y
	config_set .config BR2_PACKAGE_E2FSPROGS_UUIDGEN y
	config_set .config BR2_PACKAGE_LVM2 y
	config_set .config BR2_PACKAGE_MDADM y
	config_set .config BR2_PACKAGE_RAIDTOOLS y
	#config_set .config BR2_PACKAGE_USBUTILS y
	config_set .config BR2_PACKAGE_XFSPROGS y
	config_set .config BR2_PACKAGE_LZO y
	config_set .config BR2_PACKAGE_MICROPERL y
	config_unset .config BR2_TARGET_ROOTFS_EXT2
	#config_set .config BR2_TARGET_ROOTFS_INITRAMFS y
	config_set .config BR2_TARGET_ROOTFS_CPIO y
	# BR2_TARGET_ROOTFS_CPIO_NONE is not set
	# BR2_TARGET_ROOTFS_CPIO_GZIP is not set
	config_set .config BR2_TARGET_ROOTFS_CPIO_BZIP2 y
	# BR2_TARGET_ROOTFS_CPIO_LZMA is not set
	# BR2_TARGET_ROOTFS_CPIO_COPYTO=""

    print_info 1 'BUILDROOT Uclibc: > Configuring...'
    for def in UCLIBC_HAS_RPC UCLIBC_HAS_FULL_RPC MALLOC_GLIBC_COMPAT DO_C99_MATH UCLIBC_HAS_{RPC,CTYPE_CHECKED,WCHAR,HEXADECIMAL_FLOATS,GLIBC_CUS} PTHREADS_DEBUG_SUPPORT;do
        config_set toolchain/uClibc/uClibc-0.9.29.config ${def} "y"
    done

    print_info 1 'BUILDROOT: > Compiling...'
    compile_generic
    genkernel_generate_package "buildroot-${BUILDROOT_VER}" "."
#	cd "${CACHE_DIR}"
#	rm -rf "${UCLIBC_DIR}"     config_set .config /dev/null
#	#rm -rf "${TEMP}/staging"     config_set .config /dev/null
}
