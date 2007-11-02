require kernel_config

callback::()
{
	local CMD_CALLBACK="$(profile_get_key callback)"
	
	export KBUILD_OUTPUT
	export KERNEL_DIR

	if [ -n "${CMD_CALLBACK}" ]
	then
		print_info 1 "" 1 0
		print_info 1 "Preparing to run callback: \"${CMD_CALLBACK}\"" 0
		echo
		CALLBACK_ESCAPE=0
		CALLBACK_COUNT=0

		trap "CALLBACK_ESCAPE=1" TERM KILL INT QUIT ABRT
		while [[ ${CALLBACK_ESCAPE} -eq 0 && ${CALLBACK_COUNT} -lt 5 ]]
		do
			sleep 1; echo -n '.';
			let CALLBACK_COUNT=${CALLBACK_COUNT}+1
		done

		if [ "${CALLBACK_ESCAPE}" -eq 0 ]
		then
			echo
			eval ${CMD_CALLBACK} | tee -a ${DEBUGFILE}
			CMD_STATUS="${PIPESTATUS[0]}"
			echo
			print_info 1 "<<< Callback exit status: ${CMD_STATUS}"
			[ "${CMD_STATUS}" -ne 0 ] && die '--callback failed!'
		else
			echo
			print_info 1 ">>> Callback cancelled..."
		fi
		trap - TERM KILL INT QUIT ABRT
		print_info 1 "" 1 0
	fi
}
