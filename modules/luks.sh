require @pkg_luks-${LUKS_VER}:null:luks_compile

luks::()
{
	genkernel_convert_tar_to_cpio "luks" "${LUKS_VER}"
}

