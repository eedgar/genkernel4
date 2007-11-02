require libgpg_error
# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/libgcrypt-${LIBGCRYPT_VER}.tar.gz"

libgcrypt_compile::()
{
	local SRCTAR="${SRCPKG_DIR}/libgcrypt-${LIBGCRYPT_VER}.tar.gz" 
    local DIR="libgcrypt-${LIBGCRYPT_VER}"
    local COMMANDS ARGS

		cd "${TEMP}"
		rm -rf ${DIR} > /dev/null
		unpack ${SRCTAR} || die "Could not extract ${SRCTAR}"
		[ -d "${DIR}" ] || die '${DIR} is invalid!'
		cd "${DIR}" > /dev/null	
		gen_patch ${FIXES_PATCHES_DIR}/libgcrypt/${LIBGCRYPT_VER} .
        cp /usr/share/gnuconfig/* .

        #turn on/off the cross compiler
        if [ -n "$(profile_get_key utils-cross-compile)" ]
        then
            TARGET=$(profile_get_key utils-cross-compile)
            ARGS="${ARGS} --host=${TARGET} \
            --prefix=${TEMP}/libgcrypt-output \
            --enable-shared=no --disable-rpath \
            --disable-asm"
        else
            TARGET=$(gcc -dumpmachine)
            ARGS="${ARGS} --prefix=${TEMP}/libgcrypt-output \
            --enable-shared=no --disable-rpath --disable-asm"
        fi
        CC="$(profile_get_key utils-cross-compile)-gcc" \
        LDFLAGS="-L${LIBGPG_ERROR}/lib -L`pwd`/src/.libs/" \
        CFLAGS="-I${LIBGPG_ERROR}/include " \
        CPPFLAGS="-I${LIBGPG_ERROR}/include " \
        configure_generic ${ARGS}


		print_info 1 "Compiling libgcrypt"
        compile_generic # Compile

		[ -e ${TEMP}/libgcrypt-output ] && rm -rf ${TEMP}/libgcrypt-output
        compile_generic install # Compile
        cd ${TEMP}/libgcrypt-output
		genkernel_generate_package "libgcrypt-${LIBGCRYPT_VER}" "."
        cd ${TEMP}
        rm -r ${TEMP}/libgcrypt-output
    }
