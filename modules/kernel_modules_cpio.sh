require kernel_modules_install
kernel_modules_cpio::()
{
	if kernel_config_is_not_set "MODULES" 
	then
		print_info 1 ">> Modules not enabled in .config... skipping modules compile"
	else
		MOD_EXT=".ko"
		INSTALL_MOD_PATH="$(profile_get_key install-to-prefix)"
		
		print_info 2 "initramfs: >> Searching for modules..."

		if [ -d "${TEMP}/initramfs-modules-${KV_FULL}-temp" ]
		then
			rm -r "${TEMP}/initramfs-modules-${KV_FULL}-temp/"
		fi
		mkdir -p "${TEMP}/initramfs-modules-${KV_FULL}-temp/lib/modules/${KV_FULL}"
	
		# setup the modules profile
		setup_modules_profile
		cd ${INSTALL_MOD_PATH}	
		for i in `gen_dep_list`
		do
			mymod=`find ./lib/modules/${KV_FULL} -name "${i}${MOD_EXT}" 2>/dev/null| head -n 1 `
			if [ -z "${mymod}" ]
			then
				print_warning 2 "Warning :: ${i}${MOD_EXT} not found; skipping..."
				continue;
			fi
			
			print_info 2 "initramfs: >> Copying ${i}${MOD_EXT}..."
			cp -ax --parents "${mymod}" "${TEMP}/initramfs-modules-${KV_FULL}-temp"
		done

		if [ -f "$(profile_get_key install-to-prefix)"/lib/modules/${KV_FULL}/modules.dep ]
		then
			print_info 2 "Copying modules.dep into the initramfs"
			cp -ax --parents "./lib/modules/${KV_FULL}/modules.dep" "${TEMP}/initramfs-modules-${KV_FULL}-temp/"
		fi
		
	
		mkdir -p "${TEMP}/initramfs-modules-${KV_FULL}-temp/etc/modules/"
		
		for i in $(profile_list); do
			if [ "${i:0:16}" == "modules-cmdline-" ]
				then
					profile_copy $i "modules"
			fi
		done
		profile_copy "modules-cmdline" "modules"
	
		[ "$(profile_get_key debuglevel)" -gt "4" ] && print_info 1 "modules to be tested at bootup"
		for i in $(profile_list_keys "modules")
		do	
			[ "$(profile_get_key debuglevel)" -gt "4" ] && print_info 1 "${i#module-}: $(profile_get_key $i "modules")"
			[ -f "${TEMP}/initramfs-modules-${KV_FULL}-temp/etc/modules/${i#module-}" ] \
					&& rm "${TEMP}/initramfs-modules-${KV_FULL}-temp/etc/modules/${i#module-}"
			echo $(profile_get_key $i "modules") \
				> "${TEMP}/initramfs-modules-${KV_FULL}-temp/etc/modules/${i#module-}"
		done
	
		# Generate CPIO
		cd "${TEMP}/initramfs-modules-${KV_FULL}-temp/"
		
		genkernel_generate_cpio_path kernel-modules-${KV_FULL} .
		initramfs_register_cpio kernel-modules-${KV_FULL}
	fi
}

gen_dep_list() {
	local i
	rm -f ${TEMP}/moddeps > /dev/null
	for i in $(profile_list_keys "modules")
	do
		gen_deps $(profile_get_key $i "modules")
	done
	
	# Only list each module once
	if [ -f ${TEMP}/moddeps ]
	then
		cat ${TEMP}/moddeps | sort | uniq
	fi
}

gen_deps () {
	local modlist
	local deps
	local x

	for x in ${*}
	do
		echo ${x} >> ${TEMP}/moddeps
		
		modlist=`modules_dep_list ${x}`
		
		if [ "${modlist}" != "" -a "${modlist}" != " " ]
		then
			deps=`strip_mod_paths ${modlist}`
		else
			deps=""
		fi
		for y in ${deps}
		do
			echo ${y} >> ${TEMP}/moddeps
		done

	done
}

strip_mod_paths()
{
        local x
        local ret
        local myret

        for x in ${*}
        do
                ret=`basename ${x} | cut -d. -f1`
                myret="${myret} ${ret}"
        done
        echo "${myret}"
}

modules_dep_list() {
	MOD_EXT=".ko"
	if [ -f ${INSTALL_MOD_PATH}/lib/modules/${KV_FULL}/modules.dep ]
	then
		cat ${INSTALL_MOD_PATH}/lib/modules/${KV_FULL}/modules.dep | grep ${1}${MOD_EXT}\: 2>/dev/null | cut -d\:  -f2
	fi
}


