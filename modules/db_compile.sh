#logicTrue $(profile_get_key internal-uclibc) && require gcc
# Check that these files exist if we are compiling"
files_register "${SRCPKG_DIR}/db-${DB_VER}.tar.gz"

db_compile::() {
	local DB_DIR="db-${DB_VER}" DB_SRCTAR="${SRCPKG_DIR}/db-${DB_VER}.tar.gz"
	[ -f "${DB_SRCTAR}" ] || die "Could not find DB source tarball: ${DB_SRCTAR}!"

	cd "${TEMP}"
	rm -rf "${TEMP}/${DB_DIR}"
	rm -rf "${TEMP}/db-output"
	unpack "${DB_SRCTAR}" || die "Failed to unpack DB sources!"
	[ -d "${DB_DIR}" ] || die "DB directory ${DB_DIR} invalid!"

	cd "${DB_DIR}"
	chmod -R u+w dist
	cp /usr/share/gnuconfig/* dist
	cd "build_unix"
	print_info 1 'DB: >> Configuring...'

	# turn on/off the cross compiler
	if [ -n "$(profile_get_key utils-cross-compile)" ]
	then
		TARGET="$(profile_get_key utils-cross-compile)"
	else
		TARGET=$(gcc -dumpmachine)
	fi

	print_info 1 'db: >> Configuring...'
	CC=${TARGET}-gcc ../dist/configure --host=${TARGET} --enable-static --prefix=${TEMP}/db-output
	
	print_info 1 'db: >> Compiling...'
	mkdir -p ${TEMP}/db-output/lib/
	mkdir -p ${TEMP}/db-output/include/
	
	CC=${TARGET}-gcc \
	compile_generic
	
	compile_generic install_lib
	compile_generic install_include

	cd "${TEMP}/db-output"
	genkernel_generate_package "db-${DB_VER}" . || die 'Could not create db package!'

	cd "${TEMP}"
	rm -rf "${TEMP}/db-output" 
	rm -rf "${TEMP}/${DB_DIR}" 

}
