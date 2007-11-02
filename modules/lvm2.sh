require @pkg_lvm2-${LVM2_VER}:null:lvm2_compile

cfg_register "BLK_DEV_DM" "REQUIRED for a fully functional lvm"
cfg_register "DM_SNAPSHOT" "Recommended for a fully functional lvm"
cfg_register "DM_MIRROR" "Recommended for a fully functional lvm"
	
lvm2::()
{
	genkernel_convert_tar_to_cpio "lvm2" "${LVM2_VER}"
	kernel_cmdline_register 'add "dolvm2" for lvm2 support'

}
