require kernel_modules_compile

kernel_modules_install::()
{
    local INSTO

    INSTO="$(profile_get_key install-to-prefix)"
    mkdir -p "${INSTO}" &> /dev/null
    [ ! -w "${INSTO}" ] && die "Could not write to ${INSTO}.  Set install-to-prefix to a writeable directory or run as root."

    if kernel_config_is_not_set "MODULES"; then
	print_info 1 ">> Modules not enabled in .config... skipping modules install"
    else
	setup_kernel_args
	KERNEL_ARGS="${KERNEL_ARGS} INSTALL_MOD_PATH=${INSTO}"
	
	cd $(profile_get_key kernel-tree)
	
	# install the modules
	print_info 1 '>> Installing kernel modules ...'
	compile_generic ${KERNEL_ARGS} modules_install
    fi

    print_info 1 "Kernel modules installed in ${BOLD}${INSTO}${NORMAL}"
    cd "${INSTO}"
    print_info 1 "$(du -sch --no-dereference lib | tail -n1)"
}
