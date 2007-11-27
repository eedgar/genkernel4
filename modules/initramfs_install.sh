require initramfs_create

initramfs_install::() {

    local INSTO ARGS KNAME
    
    INSTO="$(profile_get_key install-to-prefix)$(profile_get_key bootdir)"
    mkdir -p "${INSTO}" &> /dev/null
    [ ! -w "${INSTO}" ] && die "Could not write to ${INSTO}.  Set install-to-prefix/bootdir to a writeable directory or run as root."

    if logicTrue $(profile_get_key internal-initramfs); then
	print_info 1 "Skipping installation of the initramfs: --initramfs-internal enabled"
    else
	[ "$(profile_get_key debuglevel)" -gt "1" ] && ARGS="-v"
	cp ${ARGS} "${TEMP}/initramfs-output.cpio.gz" "${INSTO}/initramfs-${KV_FULL}"
	print_info 1 ">> initramfs installed in ${BOLD}${INSTO}${NORMAL}"
	cd "${INSTO}"
	print_info 1 "$( du -h initramfs-${KV_FULL} )"
    fi
}
