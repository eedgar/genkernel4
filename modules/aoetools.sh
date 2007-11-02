require @pkg_aoetools-${AOETOOLS_VER}:null:aoetools_compile

aoetools::()
{
	genkernel_convert_tar_to_cpio "aoetools" "${AOETOOLS_VER}"
}

