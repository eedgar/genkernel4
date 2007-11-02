require @pkg_klibc-${KLIBC_VER}:null:klibc_compile

klibc::()
{
	cd ${TEMP}
	rm -rf "klibc-build-${KLIBC_VER}"
	genkernel_extract_package "klibc-${KLIBC_VER}"

	# Export KLCC location for udev and others
	KLCC="${TEMP}/klibc-build-${KLIBC_VER}/bin/klcc"

	# Update the klcc binary to reflect path changes
	local klibc_path="${TEMP}/klibc-build-${KLIBC_VER}/lib/klibc"
	local klibc_path_escaped="${klibc_path//\//\\\/}" # We add a extra '\' so the escape carries
							  # through the sed

	sed -i 	-e 's#$prefix = .*$#$prefix = "'"${klibc_path_escaped}"'";#' \
		-e 's#@prefix = .*$#@prefix = qw('"${klibc_path}"');#' \
		-e 's#$bindir = .*$#$bindir = "'"${klibc_path_escaped}"'\\/bin";#' \
		-e 's#@bindir = .*$#@bindir = qw('"${klibc_path}"'/bin);#' \
		-e 's#$libdir = .*$#$libdir = "'"${klibc_path_escaped}"'\\/lib";#' \
		-e 's#@libdir = .*$#@libdir = qw('"${klibc_path}"'/lib);#' \
		-e 's#$includedir = .*$#$includedir = "'"${klibc_path_escaped}"'\\/include";#' \
		-e 's#@includedir = .*$#@includedir = qw('"${klibc_path}"'/include);#' "${KLCC}"
}
