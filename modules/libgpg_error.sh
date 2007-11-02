require @pkg_libgpg_error-${LIBGPG_ERROR_VER}:null:libgpg_error_compile

libgpg_error::()
{
    #Export popt for dependents
	export LIBGPG_ERROR="${TEMP}/libgpg_error-output"    
    [ -e ${LIBGPG_ERROR} ] && rm -rf ${LIBGPG_ERROR}
    mkdir -p ${LIBGPG_ERROR}
    cd ${LIBGPG_ERROR}
    
    genkernel_extract_package "libgpg_error-${LIBGPG_ERROR_VER}"
}
