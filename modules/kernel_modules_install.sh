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

        print_info 1 "Kernel modules installed in ${BOLD}${INSTO}${NORMAL}"
        cd "${INSTO}"
        print_info 1 "$(du -sch --no-dereference lib | tail -n1)"
        print_info 1 "Updating module dependencies"
        /sbin/depmod -b ${INSTO} ${KV_FULL}


        print_info 1 "Preparing a build directory for eventual external modules"
        build_dir="/usr/src/linux-${KV_FULL}-build"
        output_build="${INSTO}${build_dir}"
        mkdir -p "$output_build" 2>/dev/null
        cd $(profile_get_key kernel-tree)

        compile_generic O="${output_build}" mrproper
        cp "$KBUILD_OUTPUT/Module.symvers" "$KBUILD_OUTPUT/.config" "$output_build"
        compile_generic O="${output_build}" modules_prepare

        # include2 contains a symlink, which we don't want for portability
        # so : we copy everything locally
        #
        # According to the top-level kernel Makefile, this include2
        # dir only contains an asm symlink.
        cd "${output_build}"/include2
        mkdir .tmp
        cp -a asm/* .tmp
        rm -f asm
        mv .tmp asm

        # fix the build symlink, remove the source one for portability
        cd "${INSTO}/lib/modules/${KV_FULL}"
        rm build source
        ln -s ../../.."${build_dir}" build

        print_info 1 "Kernel build directory installed in ${BOLD}${output_build}${NORMAL}"
        cd "${INSTO}"
        print_info 1 "$(du -sch --no-dereference usr | tail -n1)"
    fi
}
