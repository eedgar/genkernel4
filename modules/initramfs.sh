if logicTrue $(profile_get_key install)
then
	require initramfs_install
else
	require initramfs_create
fi

kernel_cmdline_register 'root=/dev/ram0 real_root=/dev/$ROOT init=/linuxrc'
kernel_cmdline_register ''
kernel_cmdline_register '    Where $ROOT is the device node for your root partition as the'
kernel_cmdline_register '    one specified in /etc/fstab'
kernel_cmdline_register ''

if ! logicTrue $(profile_get_key internal-initramfs)
then
	kernel_cmdline_register "If you require Genkernel's hardware detection features; you MUST"
	kernel_cmdline_register 'tell your bootloader to use the provided initramfs file.'
	kernel_cmdline_register ''
fi

initramfs::() { true; }
