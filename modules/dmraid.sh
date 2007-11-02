require @pkg_dmraid-${DMRAID_VER}:null:dmraid_compile

dmraid::()
{
	genkernel_convert_tar_to_cpio "dmraid" "${DMRAID_VER}"
	kernel_cmdline_register 'add "dodmraid" for dmraid support'
	kernel_cmdline_register '   or "dodmraid=<additional options>"'
}
