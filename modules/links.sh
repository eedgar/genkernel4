require kernel
logicTrue $(external_initramfs) && require initramfs

links::()
{
	local ARGS CP_ARGS KNAME BOOTDIR

	cd "$(profile_get_key install-to-prefix)$(profile_get_key bootdir)"
	if logicTrue $(profile_get_key links)
	    for i in kernel initramfs System.map; do
		if [ -e "${i}-${KV_FULL}" ]; then
		    ln -sf "${i}-${KV_FULL}" "${i}"
		fi
	    done
	else
	    print_info 1 "Skipping link creation: --no-install enabled"
	fi
}
