require @pkg_open-iscsi-${OPENISCSI_VER}-tools:null:open_iscsi_tools_compile
require open_iscsi_modules_compile

open_iscsi::()
{
	genkernel_convert_tar_to_cpio "open-iscsi" "${OPENISCSI_VER}-tools"
	genkernel_convert_tar_to_cpio "open-iscsi" "${OPENISCSI_VER}-modules-${KV_FULL}"
}

