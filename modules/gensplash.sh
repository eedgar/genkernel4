gensplash::() {
	if [ -x /sbin/splash_geninitramfs ]
	then
		[ -z "$(profile_get_key gensplash-theme)" ] && [ -e /etc/conf.d/splash ] && source /etc/conf.d/splash
		[ -z "$(profile_get_key gensplash-theme)" ] && GENSPLASH_THEME=default
		[ -n "$(profile_get_key gensplash-theme)" ] && GENSPLASH_THEME="$(profile_get_key gensplash-theme)"

		print_info 1 "  >> Installing gensplash [ using the ${GENSPLASH_THEME} theme ]..."
		cd /

		local tmp=""
		[ -n "$(profile_get_key gensplash-res)" ] && tmp="-r $(profile_get_key gensplash-res)"
		[ -e ${TEMP}/gensplash-${GENSPLASH_THEME}.cpio.gz ] && rm ${TEMP}/gensplash-${GENSPLASH_THEME}.cpio.gz

		splash_geninitramfs -g ${TEMP}/gensplash-${GENSPLASH_THEME}.cpio.gz ${tmp} ${GENSPLASH_THEME}
		initramfs_register_external_cpio ${TEMP}/gensplash-${GENSPLASH_THEME}.cpio.gz		
		kernel_cmdline_register "add \"vga=791 splash=silent,theme:${GENSPLASH_THEME} CONSOLE=/dev/tty1 quiet\" if you use a gensplash framebuffer ]"
	else
		print_warning 1 '               >> No splash detected; skipping!'
	fi

	if [ -x /sbin/suspend2ui_fbsplash ]
	then
		print_info 1 "  >> Installing suspend2ui_fbsplash..."

		genkernel_generate_cpio_files suspend2-userui /sbin/suspend2ui_fbsplash
		initramfs_register_external_cpio ${TEMP}/suspend2-userui.cpio.gz
	fi
}
