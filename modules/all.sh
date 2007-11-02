if logicTrue $(profile_get_key install) && logicTrue $(profile_get_key mountboot)
then
	require mount_boot
fi

require kernel

logicTrue $(initramfs) && require initramfs

if logicTrue $(profile_get_key install) 
then
	logicTrue $(profile_get_key links) && require links
	logicTrue $(profile_get_key setgrub) && require grub
fi

all::() { 


cfg_register_read
kernel_cmdline_register_read

print_info 1 ">> Genkernel completed successfully..."
}
