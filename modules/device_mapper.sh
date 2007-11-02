require @pkg_device-mapper.${DEVICE_MAPPER_VER}:null:device_mapper_compile

device_mapper::()
{
	cd ${TEMP}
	rm -rf "${TEMP}/device-mapper"
	genkernel_extract_package "device-mapper.${DEVICE_MAPPER_VER}"

	# Export device-mapper for dependents
	export DEVICE_MAPPER="${TEMP}/device-mapper"
}
