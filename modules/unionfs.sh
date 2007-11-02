#require @pkg_unionfs-${UNIONFS_VER}-tools:null:unionfs_tools_compile
#require unionfs_modules_compile

unionfs::()
{
#	genkernel_convert_tar_to_cpio "unionfs" "${UNIONFS_VER}-tools"
#	if kernel_config_is_not_set "UNION_FS"
#	then
#		genkernel_convert_tar_to_cpio "unionfs" "${UNIONFS_VER}-modules-${KV_FULL}"
#	fi
print_info 1 "Unionfs support is deprecated. Use aufs instead"
}
