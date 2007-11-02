require @pkg_gcc-stage1-${GCC_VER}:null:gcc_stage1_compile
gcc_stage1::()
{
	mkdir -p ${TEMP}/staging
	cd ${TEMP}/staging
	genkernel_extract_package "gcc-stage1-${GCC_VER}"

	GCC_TARGET_ARCH=$(echo ${ARCH} | sed -e s'/-.*//' \
		-e 's/x86$/i386/' \
		-e 's/i.86$/i386/' \
		-e 's/sparc.*/sparc/' \
		-e 's/arm.*/arm/g' \
		-e 's/m68k.*/m68k/' \
		-e 's/ppc/powerpc/g' \
		-e 's/v850.*/v850/g' \
		-e 's/sh[234].*/sh/' \
		-e 's/mips.*/mips/' \
		-e 's/mipsel.*/mips/' \
		-e 's/cris.*/cris/' \
		-e 's/nios2.*/nios2/' \
	)

	profile_set_key utils-cross-compile "${TEMP}/staging/bin/${GCC_TARGET_ARCH}-linux-uclibc-"

}
