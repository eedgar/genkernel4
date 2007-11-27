require kernel_compile

kernel_install::()
{
    local INSTO CP_ARGS KNAME

    INSTO="$(profile_get_key install-to-prefix)$(profile_get_key bootdir)"
    mkdir -p "${INSTO}" &> /dev/null
    [ ! -w "${INSTO}" ] && die "Could not write to ${INSTO}.  Set install-to-prefix/bootdir to a writeable directory or run as root."

    
    KERNEL_ARGS="${KERNEL_ARGS} INSTALL_PATH=${INSTO}"

    KNAME="$(profile_get_key kernel-name)"
    setup_kernel_args

    cd "$(profile_get_key kbuild-output)"

    print_info 1 '>> Installing kernel ...'

    [ "$(profile_get_key debuglevel)" -gt "1" ] && CP_ARGS="-v"

    cp ${CP_ARGS} "$(profile_get_key kernel-binary)" "${INSTO}/kernel-${KV_FULL}"
    cp ${CP_ARGS} "System.map" "${INSTO}/System.map-${KV_FULL}"
    print_info 1 "Kernel installed in ${BOLD}${INSTO}${NORMAL} :"

    cd "${INSTO}"
    print_info 1 "$( du -h kernel-${KV_FULL} )"
    print_info 1 "$( du -h System.map-${KV_FULL} )"
    cd - &>/dev/null

    if [ -w "/etc/kernels" ]; then
	print_info 1 "Kernel config saved to:"
	print_info 1 "   ${BOLD}/etc/kernels/kernel-${KV_FULL}.config${NORMAL}"
	cp ${CP_ARGS} .config "/etc/kernels/kernel-${KV_FULL}.config"
    else
	print_info 1 "Kernel config saved to:"
	print_info 1 "   ${BOLD}${INSTO}/kernel-${KV_FULL}.config${NORMAL}"
	cp ${CP_ARGS} .config "${INSTO}/kernel-${KV_FULL}.config"
    fi
}
