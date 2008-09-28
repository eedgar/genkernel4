
# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/libgpg-error-${LIBGPG_ERROR_VER}.tar.bz2"

libgpg_error_compile::()
{
	local SRCTAR="${SRCPKG_DIR}/libgpg-error-${LIBGPG_ERROR_VER}.tar.bz2"
    local DIR="libgpg-error-${LIBGPG_ERROR_VER}"
    local COMMANDS ARGS

		cd "${TEMP}"
		rm -rf "${DIR}" > /dev/null
		unpack "${SRCTAR}" || die "Could not extract ${SRCTAR}"
		[ -d "${DIR}" ] || die '${DIR} is invalid!'
		cd "${DIR}" > /dev/null	
		gen_patch ${FIXES_PATCHES_DIR}/libgpg_error/${LIBGPG_ERROR_VER} .
        cp /usr/share/gnuconfig/* .

        #turn on/off the cross compiler
        if [ -n "$(profile_get_key utils-cross-compile)" ]
        then
            TARGET=$(profile_get_key utils-cross-compile)
            ARGS="${ARGS} --host=${TARGET} --disable-shared"
        else
            TARGET=$(gcc -dumpmachine)
        fi
        CC="$(profile_get_key utils-cross-compile)-gcc" \
        configure_generic ${ARGS} --prefix=${TEMP}/libgpg_error-output

		print_info 1 "Compiling libgpg_error"
        ARGS=""
        compile_generic  # Compile

		[ -e ${TEMP}/libgpg_error-output ] && rm -rf ${TEMP}/libgpg_error-output
        compile_generic install # Compile
        cd ${TEMP}/libgpg_error-output
		genkernel_generate_package "libgpg_error-${LIBGPG_ERROR_VER}" "."
        cd ${TEMP}
        rm -r ${TEMP}/libgpg_error-output
}
