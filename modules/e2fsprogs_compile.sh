# Output: binpackage { / -> blkid }
# Placement: TBD
logicTrue $(profile_get_key internal-uclibc) && require gcc

# Check that these files exist if we are compiling"
files_register "${E2FSPROGS_SRCTAR}"
e2fsprogs_compile::() {
	local E2FSPROGS_DIR="e2fsprogs-${E2FSPROGS_VER}"

	cd "${TEMP}"
	[ ! -f "${E2FSPROGS_SRCTAR}" ] &&
		die "Could not find e2fsprogs source tarball: ${E2FSPROGS_SRCTAR}. Please place it there, or place another version, changing /etc/genkernel.conf as necessary!"

	rm -rf "${E2FSPROGS_DIR}"
	unpack "${E2FSPROGS_SRCTAR}" || die "Could not extract e2fsprogs tarball: ${E2FSPROGS_SRCTAR}"
	[ -d "${E2FSPROGS_DIR}" ] || die "e2fsprogs directory ${E2FSPROGS_DIR} invalid"
	cd "${E2FSPROGS_DIR}"

    # turn on/off the cross compiler
    if [ -n "$(profile_get_key utils-cross-compile)" ]
    then
		TARGET=$(profile_get_key utils-cross-compile)
        ARGS="${ARGS} --host=$(${TARGET}-gcc -dumpmachine)"
	else
		TARGET=$(gcc -dumpmachine)
		
    fi

	print_info 1 'e2fsprogs: >> Configuring...'
	
	CC=${TARGET}-gcc \
	CXX=${TARGET}-g++ \
	configure_generic  --with-ldopts=-static --prefix=${TEMP}/e2fsprogs-out ${ARGS}

	print_info 1 'e2fsprogs: >> Compiling...'
	
	CC=${TARGET}-gcc \
	CXX=${TARGET}-g++ \
	compile_generic V=1 # Run make
	
	compile_generic install
	compile_generic install-libs 

	print_info 1 'e2fsprogs: >> Copying to cache...'

	cd "${TEMP}/e2fsprogs-out"
	genkernel_generate_package "e2fsprogs-${E2FSPROGS_VER}" "." || die 'Could not generate e2fsprogs binary package!'
	cd "${TEMP}"
	rm -rf "${E2FSPROGS_DIR}" > /dev/null
	rm -rf "${TEMP}/e2fsprogs-out" > /dev/null
}
