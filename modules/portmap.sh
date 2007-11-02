require @pkg_portmap-${PORTMAP_VER}:null:portmap_compile

portmap::()
{
	genkernel_convert_tar_to_cpio "portmap" "${PORTMAP_VER}"
}
