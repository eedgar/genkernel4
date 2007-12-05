require @kernel_src_tree:null:fail
kernel_config::()
{
	PRINT_PREFIX="config: "
	setup_kernel_args

	# Check that the asm-${ARCH} link is valid
	#if [ "${ARCH}" == "xen0" -o "${ARCH}" == "xenU" ]
	#then
	#	check_asm_link_ok xen || die "Bad asm link.  The output directory has already been configured for a different arch"
	#elif [ "${ARCH}" == "x86" ]
	#then
	#	check_asm_link_ok i386 || die "Bad asm link.  The output directory has already been configured for a different arch"
	#elif [ "${ARCH}" == "ppc64" ]
	#then
	#	check_asm_link_ok powerpc || die "Bad asm link.  The output directory has already been configured for a different arch"
	#else
	#	check_asm_link_ok ${ARCH} || die "Bad asm link.  The output directory has already been configured for a different arch"
	#fi

	cd $(profile_get_key kernel-tree)

	# Make a backup of the config if we are going to clean
	logicTrue $(profile_get_key clean) && cp $(profile_get_key kbuild-output)/.config \
		$(profile_get_key kbuild-output)/.config.genkernel_backup > /dev/null 2>&1

	# CLEAN
	# Source dir needs to be clean or kbuild complains
	if [ "$(profile_get_key kbuild-output)" != "$(profile_get_key kernel-tree)" ]
	then

	    print_info 1 '>> Cleaning kernel source tree...'
	    print_info 1 '   Run "make mrproper" as root if this fails'
	    compile_generic mrproper
            
	    # Mismatched kbuild_outputs and kernel source trees give errors
	    if ! cat ${KBUILD_OUTPUT}/include/config/kernel.release 2>/dev/null | egrep "^${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}" &>/dev/null; then
		print_info 1 "Cleaning kbuild_output to build a new kernel version"
		rm -rf ${KBUILD_OUTPUT}/*
	    fi

            if [ -f "$(profile_get_key kernel-tree)/localversion-genkernel" ]
            then
                rm -f "$(profile_get_key kernel-tree)/localversion-genkernel" >/dev/null 2>&1
                if [ -f "$(profile_get_key kernel-tree)/localversion-genkernel" ]
                then
		    die "Could not remove localversion-genkernel from the Kernel source tree. Please remove it manually."
                fi
            fi
	fi
	
	logicTrue $(profile_get_key mrproper) && \
		print_info 1 '>> Running mrproper...' && \
			compile_generic ${KERNEL_ARGS} mrproper

	# Setup fake i386 kbuild_output for arch=um or xen0 or xenU 
	# Some proggies need a i386 configured kernel tree
	if [ 	"$(profile_get_key arch)" == "um" ]
	then
		print_info 1 "${PRINT_PREFIX}>> Creating $(profile_get_key arch)-i386 kernel environment"
		KRNL_TMP_DIR="${TEMP}/genkernel-kernel-$(profile_get_key arch)-i386"
		mkdir -p "${KRNL_TMP_DIR}"
		yes '' 2>/dev/null | compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" oldconfig
		compile_generic ARCH=i386 "KBUILD_OUTPUT=${KRNL_TMP_DIR}" modules_prepare
	fi
	
	if logicTrue $(profile_get_key clean)
	then
		print_info 1 'kernel configure: >> Running clean...' 
		compile_generic ${KERNEL_ARGS} clean
	fi

	
	determine_config_file
	print_info 1 "${PRINT_PREFIX}Using kernel config from ${KERNEL_CONFIG}"
	cp "${KERNEL_CONFIG}" "$(profile_get_key kbuild-output)/.config" ||\
	    die 'Could not copy configuration file!'

	if logicTrue $(profile_get_key clean)
	then
		print_info 1 'kernel configure: >> Running clean...' 
		compile_generic ${KERNEL_ARGS} clean
	else
		print_info 1 "${PRINT_PREFIX}--no-clean is enabled; leaving the .config alone."	
	fi

	# Manual Configure
	if logicTrue $(profile_get_key defconfig)
	then
		print_info 1 "${PRINT_PREFIX}>> Running defconfig..."
		compile_generic ${KERNEL_ARGS} defconfig
		[ "$?" ] || die 'Error: defconfig failed!'
	fi

	if logicTrue $(profile_get_key menuconfig)
	then 
		print_info 1 "${PRINT_PREFIX}>> Running menuconfig..."
		compile_generic runtask ${KERNEL_ARGS} menuconfig
		[ "$?" ] || die 'Error: menuconfig failed!'
	fi

	if logicTrue $(profile_get_key config)
	then 
		print_info 1 "${PRINT_PREFIX}>> Running config..."
		compile_generic runtask ${KERNEL_ARGS} config
		[ "$?" ] || die 'Error: config failed!'
	fi
	
	if logicTrue $(profile_get_key xconfig)
	then 
		print_info 1 "${PRINT_PREFIX}>> Running xconfig..."
		compile_generic ${KERNEL_ARGS} xconfig
		[ "$?" ] || die 'Error: xconfig failed!'
	fi
	if logicTrue $(profile_get_key gconfig)
	then
		print_info 1 "${PRINT_PREFIX}>> Running gconfig..."
		compile_generic ${KERNEL_ARGS} gconfig
		[ "$?" ] || die 'Error: gconfig failed!'
	fi
	
	if logicTrue $(profile_get_key allmodconfig)
	then
		print_info 1 "${PRINT_PREFIX}>> Running allmodconfig..."
		compile_generic ${KERNEL_ARGS} allmodconfig
		[ "$?" ] || die 'Error: allmodconfig failed!'
	fi
	
	if logicTrue $(profile_get_key allyesconfig)
	then
		print_info 1 "${PRINT_PREFIX}>> Running allyesconfig..."
		compile_generic ${KERNEL_ARGS} allyesconfig
		[ "$?" ] || die 'Error: allyesconfig failed!'
	fi
	
	if logicTrue $(profile_get_key allnoconfig)
	then
		print_info 1 "${PRINT_PREFIX}>> Running allnoconfig..."
		compile_generic ${KERNEL_ARGS} allnoconfig
		[ "$?" ] || die 'Error: allnoconfig failed!'
	fi
	
	# FIXME: config_cleanup_register events need dealing with here

	# apply the ppc fix?
	if [ "$(profile_get_key arch)" = 'ppc' -o "$(profile_get_key arch)" = 'ppc64' ]
	then
		print_info 1 '>> Applying hack to workaround 2.6.14+ PPC header breakages...'
		compile_generic ${KERNEL_ARGS} 'include/asm'
	fi


        # Run oldconfig now... if nothing was configured at least
        # we end up in a good state; else it won't change anything
	print_info 1 "${PRINT_PREFIX}>> Final pass at oldconfig to make sure everything is OK..."
	yes '' 2>/dev/null | compile_generic ${KERNEL_ARGS} oldconfig
	[ "$?" ] || die 'Error: oldconfig failed!'

	# Turn on things that have to be on below ... 	

	# Set the initramfs_source string if building an internal initramfs.
	# You cannot use kernel_config_is_set 'INITRAMFS_SOURCE' as the unset value is ""
	# which is actually technically set ;-)

	# So, if this is not empty, then a initramfs is set.
	if logicTrue $(internal_initramfs)
	then
	        if [ "$(kernel_config_get "INITRAMFS_SOURCE")" == "\"\"" ]; then
			kernel_config_set_string "INITRAMFS_SOURCE" "${TEMP}/initramfs-internal ${TEMP}/initramfs-internal.devices"
			kernel_config_set_raw "INITRAMFS_ROOT_UID" 0
			kernel_config_set_raw "INITRAMFS_ROOT_GID" 0
			UPDATED_KERNEL=true
		fi
	else
		if [ "$(kernel_config_get "INITRAMFS_SOURCE")" != "\"\"" ]; then
		    echo "printbl"
			kernel_config_unset "INITRAMFS_SOURCE"
			kernel_config_unset "INITRAMFS_ROOT_UID"
			kernel_config_unset "INITRAMFS_ROOT_GID"
			UPDATED_KERNEL=true
		fi
	fi

	# Sets UPDATED_KERNEL to true if any config options are not defined
	logicTrue $(profile_get_key force-config) && cfg_register_enable
	if [ "${UPDATED_KERNEL}" == 'true' ]
	then
		yes '' 2>/dev/null | compile_generic ${KERNEL_ARGS} oldconfig
	fi

	compile_generic ${KERNEL_ARGS} prepare
	if [ "$(kernel_config_get "MODULES")" = 'yes' ]; then
		compile_generic ${KERNEL_ARGS} modules_prepare
	fi

	# if modules capable compile_generic ${KERNEL_ARGS} modules_prepare
	# Set or unset any config option
	#kernel_config_unset "AUDIT"
	#kernel_config_set_module "AUDIT"
	#kernel_config_set_builtin "AUDIT"
	
	# Kernel configuration may have changed our output names ..
	unset KV_FULL
	get_KV $(profile_get_key kernel-tree)
	cd $(profile_get_key kbuild-output)
	genkernel_generate_package "kernel-config-${KV_FULL}" ".config"
}
