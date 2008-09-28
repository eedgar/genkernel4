require @pkg_libgcrypt-${LIBGCRYPT_VER}:null:libgcrypt_compile

libgcrypt::()
{
    #Export libgcrypt for dependents
	export LIBGCRYPT="${TEMP}/libgcrypt-staging"    
    [ -e "${LIBGCRYPT}" ] && rm -rf "${LIBGCRYPT}"
    mkdir -p "${LIBGCRYPT}"
    cd "${LIBGCRYPT}"
    
    genkernel_extract_package "libgcrypt-${LIBGCRYPT_VER}"
}

