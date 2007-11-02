
# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/cryptsetup-luks-${LUKS_VER}.tar.bz2"
require e2fsprogs popt device_mapper libgcrypt libgpg_error 
luks_compile::()
{
	local LUKS_SRCTAR="${SRCPKG_DIR}/cryptsetup-luks-${LUKS_VER}.tar.bz2" LUKS_DIR="cryptsetup-luks-${LUKS_VER}"
    local COMMANDS ARGS

		cd "${TEMP}"
		rm -rf ${LUKS_DIR} > /dev/null
		unpack ${LUKS_SRCTAR} || die 'Could not extract aoetools source tarball!'
		[ -d "${LUKS_DIR}" ] || die 'aoetools directory ${AOETOOLS_DIR} is invalid!'
		cd "${LUKS_DIR}" > /dev/null	
		gen_patch ${FIXES_PATCHES_DIR}/luks/${LUKS_VER} .
        cp /usr/share/gnuconfig/* .
        #turn on/off the cross compiler
        if [ -n "$(profile_get_key utils-cross-compile)" ]
        then
            TARGET=$(profile_get_key utils-cross-compile)
            ARGS="${ARGS} --host=${TARGET}"
        else
            TARGET=$(gcc -dumpmachine)
        fi

        CC=${TARGET}-gcc \
        LDFLAGS="-L${E2FSPROGS}/lib -L${POPT}/lib -L${DEVICE_MAPPER}/lib \
        -L${LIBGCRYPT}/lib -L${LIBGPG_ERROR}/lib" \
        CFLAGS="-I${E2FSPROGS}/include -I${POPT}/include \
        -I${DEVICE_MAPPER}/include -I${LIBGCRYPT}/include \
        -I${LIBGPG_ERROR}/include" \
        CPPFLAGS="-I${E2FSPROGS}/include -I${POPT}/include \
        -I${DEVICE_MAPPER}/include -I${LIBGCRYPT}/include \
        -I${LIBGPG_ERROR}/include" \
        configure_generic ${ARGS} --enable-static \
        --prefix=${TEMP}/luks-output --disable-rpath --disable-shared-library


		print_info 1 "Compiling cryptsetup-luks"
        ARGS=""
        compile_generic ${ARGS} # Compile

		[ -e ${TEMP}/luks-output ] && rm -rf ${TEMP}/luks-output
		mkdir -p ${TEMP}/luks-output/sbin
        find . -name cryptsetup
        cp ./src/cryptsetup ${TEMP}/luks-output/sbin
        #compile_generic ${ARGS} install # Compile
        cd ${TEMP}/luks-output
		${TARGET}-strip sbin/cryptsetup

		genkernel_generate_package "luks-${LUKS_VER}" "."
}
