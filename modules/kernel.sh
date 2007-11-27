require kernel_install
require kernel_modules_install

if ! logicTrue $(initramfs)
then
	kernel_cmdline_register 'root=/dev/$ROOT'
	kernel_cmdline_register '[ And "vga=0x317 splash=verbose" if you use a framebuffer ]'
	kernel_cmdline_register ''
	kernel_cmdline_register 'Where $ROOT is the device node for your root partition as the'
	kernel_cmdline_register 'one specified in /etc/fstab'
fi


kernel::() { true; }
