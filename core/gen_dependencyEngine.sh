# genkernel-modular/core/gen_depedencyEngine.sh
# -- Core dependency engine

# Copyright: 2006 plasmaroo@gentoo,org
# License: GPLv2

# This module handles the dependecy requirements of genkernel, parsing
# the require and provide instructions of modules and building a relevant
# dependency tree which can then be used by the main loop to execute
# the intended result.

# We might be getting reloaded; clear up if we need a new deptree
unset __INTERNAL__DEPS__REQ_N __INTERNAL__DEPS__REQ_D __INTERNAL__DEPS__PRV_S __INTERNAL__DEPS__PRV_P \
      __MODULE__DEPS__VARS_N __MODULE__DEPS__VARS_D

# These are used for checking for cyclic loops
__INTERNAL__MODULES_LOADING=''
__INTERNAL__MODULES_LOADED=''

kernel_cmdline_unregister

declare -a __INTERNAL__DEPS__REQ_N # Name
declare -a __INTERNAL__DEPS__REQ_D # Data
declare -a __INTERNAL__DEPS__PRV_S # Source
declare -a __INTERNAL__DEPS__PRV_P # Provides
declare -a __MODULE__DEPS__VARS_N # Name
declare -a __MODULE__DEPS__VARS_D # Data

# provide_lookup provide
# Look up the module which provides "provide"; return null
# if no matches are found.
provide_lookup() {
	local n source provides

	for (( n = 0 ; n <= ${#__INTERNAL__DEPS__PRV_S[@]}; ++n )) ; do
		source=${__INTERNAL__DEPS__PRV_S[${n}]}
		provides=${__INTERNAL__DEPS__PRV_P[${n}]}

		[ "$1" = "${provides}" ] && echo "${source}" && return
	done
}

# provide {list}
# {list}: list of provides to check and register with the calling module.
provide () {
	local i myCaller myCheck
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	# Check something does not already provide this functionality,
        # unless the module is the same in which case ignore the request.
	# If no clashes are found commit the change.

	for i in $*; do
		myCheck=$(provide_lookup $i)

		if [ -n "${myCheck}" -a "${myCheck}" != "${myCaller}" ]
		then
			die "Conflicting provide ($i in ${myCaller} against $i in ${myCheck})..."
		else
			__INTERNAL__DEPS__PRV_S[${#__INTERNAL__DEPS__PRV_S[@]}]="${myCaller}"
			__INTERNAL__DEPS__PRV_P[${#__INTERNAL__DEPS__PRV_P[@]}]="$i"
		fi
	done
}

# require {list}
# Load {list} and add modules to the dependency queue. This can be invoked multiple times,
# conditionally if needed, from a module to add dependencies. Dependencies are always additive.

# {list}:item:	"xyz" - require module "xyz"
#		"@xyz" - require a module which provides "xyz". Alias for @xyz:null:fail.
#		"@xyz:yes:no" - require "yes" if a module that provides functionality "xyz"
#				exists, otherwise require "no"

#		"xyz:unset:one:two:three:..." - if the "xyz" module configuration key is unset,
#		a dependency on "unset" is formed or if the key is 0. If key is 1 require
#		"one", if the key is 2 require "two", etc.

#		"null" is a special target which does nothing and is not added to the deptree.
#		"fail" is another special target which halts deptree processing and informs
# 		that the deptree is unsatisfied at that point.

require () {
	local i myCaller myDeps myConditonalVar myLookup

	# Get Caller Module; step back twice in the execution list to get to the caller.
	myCaller=$(basename ${BASH_SOURCE[1]} .sh)

	# Guard against cyclic loops
	__INTERNAL__MODULES_LOADED="${__INTERNAL__MODULES_LOADED} ${__INTERNAL__MODULES_LOADING}"

	# Process dependency list
	myDeps="$(require_lookup ${myCaller})"
	for i in $*; do
		# Special-case for 'null'
		[ "${i}" = 'null' ] && continue
		
		# Process conditional provide-dependent deps:
		if [ "${i:0:1}" = '@' ]
		then
			# Re-alias if needed:
			[ "${i/:/}" = "${i}" ] && i="${i}:null:fail"

			# Get first term and strip @; lookup the provide
			myLookup="${i%%:*}"
			myLookup="${myLookup:1}"
			myConditionalVar="$(provide_lookup ${myLookup})"

			if [ -n "${myConditionalVar}" ]
			then
				# Success - get the second field (strip first and then leading fields)

				myConditionalVar="${i#*:}"
				myConditionalVar="${myConditionalVar%%:*}"
			else
				# Get last field
				myConditionalVar="${i##*:}"
			fi

			# Special-case for 'null' and 'fail'
			[ "${myConditionalVar}" = 'null' ] && continue
			if [ "${myConditionalVar}" = 'fail' ]
			then
				echo "Error: module ${myCaller} requires functionality ${myLookup} which is"
				echo '       unresolved. Deptree creation failed.'
				exit 255 # XXX
			fi

			# We're good; add to deptree
			myDeps="${myDeps} ${myConditionalVar}"
			continue
		fi

		# Process conditional var-defined deps:
		if [ "${i/:/}" != "${i}" ]
		then
			# Get first term (our variable name) and look it up
			myConditionalVar="${i%%:*}"
			myConditionalVar="$(require_dep_lookup ${myConditionalVar})"
			[ -z "${myConditionalVar}" ] && myConditionalVar=2 || myConditionalVar=$(( ${myConditionalVar} + 2 ))
			myDeps="${myDeps} $(echo ${i} | cut -d: -f${myConditionalVar})"

			continue
		fi

		# Otherwise just tag on the deps:
		myDeps="${myDeps} ${i}"
	done

	# For $myCaller deps are $myDeps
	require_set "${myCaller}" "${myDeps}"

	for i in ${myDeps}; do
		if ! $(has "${i}" "${__INTERNAL__MODULES_LOADED}")
		then
			# This needs to be set here so a cyclic loop is not formed
			__INTERNAL__MODULES_LOADED="${__INTERNAL__MODULES_LOADED} ${__INTERNAL__MODULES_LOADING}"
			# echo ">> Loading: $i"

			__INTERNAL__MODULES_LOADING="$i"
			if [ ! -e "${MODULES_DIR}/$i.sh" ]
			then
				echo ">> Module request [$i] not resolvable: $i.sh not found; halting..."
				exit 255
			else
				source ${MODULES_DIR}/$i.sh
			fi
		else
			# We may or may not have a cyclic loop. Traverse the call stack and see if $myCaller is in there.
			if require_SearchStackForRecursion "${myCaller}"
			then
				if require_SearchStackForRecursion "${i}"
				then
					echo ">> Cyclic loop detected in dependencies [$i:$myCaller]. Stopping recursive processing..."
					require_DebugStack
					exit 255
				fi
			fi
		fi
	done
}

require_dep_lookup() {
	local n name data

        for (( n = 0 ; n <= ${#MODULE_DEPS__VARS_N[@]}; ++n )) ; do
		name=${MODULE__DEPS__VARS_N[${n}]}
		data=${MODULE__DEPS__VARS_D[${n}]}

		[ "${name}" = "$1" ] && echo "${data}" && return
        done	
}

require_lookup() {
	local n name data

        for (( n = 0 ; n <= ${#__INTERNAL__DEPS__REQ_N[@]}; ++n )) ; do
		name=${__INTERNAL__DEPS__REQ_N[${n}]}
		data=${__INTERNAL__DEPS__REQ_D[${n}]}

		[ "${name}" = "$1" ] && echo "${data}" && return
        done
}

require_set() {
	local n

	# See if we have n, if we do overwrite. Otherwise append.
        for (( n = 0 ; n <= ${#__INTERNAL__DEPS__REQ_N[@]}; ++n )) ; do
		if [ "${__INTERNAL__DEPS__REQ_N[${n}]}" = "$1" ]
		then
			__INTERNAL__DEPS__REQ_D[${n}]="$2"
			return
		fi
        done

	# For $myCaller deps are $myDeps
	__INTERNAL__DEPS__REQ_N[${#__INTERNAL__DEPS__REQ_N[@]}]="$1"
	__INTERNAL__DEPS__REQ_D[${#__INTERNAL__DEPS__REQ_D[@]}]="$2"	
}

require_DebugStack() {
	local n name data

        for (( n = 0 ; n <= ${#__INTERNAL__DEPS__REQ_N[@]}; ++n )) ; do
		name=${__INTERNAL__DEPS__REQ_N[${n}]}
		data=${__INTERNAL__DEPS__REQ_D[${n}]}
		echo "(${name}:${data})"
        done
}

require_SearchStackForRecursion() {
	# Ignore the last n = since that is the original require call
	local n
	for (( n = 1 ; n < $(( ${#FUNCNAME[@]} - 1 )); ++n )) ; do
		[ "$(basename ${BASH_SOURCE[$(( n - 1 ))]} .sh)" = "$1" ] && return 0
	done

	return 1
}

# buildDepTreeGeneric 'module' [carryIn]
# 'module': module to develop a depedency tree for
# [carryIn]: do not assign, used internally for cyclic checks

buildDepTreeGeneric () {
	local dep localTree resultTree myDeps myDone returnVal
	myDeps=$(require_lookup $1)

	# Check if we are at the end of our tree, if so, return and
	# start recursing backwards...
        [ "${myDeps}" = '' ] && return
	myDone="$2"

	for dep in ${myDeps}; do
		myDone="$2" # I think we need this here rather than above...

		if ! has "${dep}" "${localTree}"
		then
			# See if this node has already been processed /in the recursion/. If it has, we're going
			# round so halt.
			has "${dep}" "${myDone}" && echo ">> Circular dependency: $dep" >/dev/stderr

			# Add dep to myDone so a recursive loop can be detected further on in the recursion
			# if it so happens.
			myDone="${myDone} ${dep}"

			# Find deps of ${dep}
			returnVal=$(buildDepTreeGeneric "${dep}" "${myDone}" "${3}")

			# ${dep} doesn't need to be removed from ${myDone} as ${myDone} is reloaded
			# on each cycle anyway.

			# Add any new dependencies to our local output tree
			for result in ${returnVal}; do
				has "${result}" "${localTree}" || localTree="${localTree} ${result}"
			done

			# Add ${dep} to tree to tree as we've now processed ${dep}'s dependencies.
			localTree="${localTree} ${dep}"
		fi
	done

	echo $localTree # Return value
}

buildDepTreeSolution()
{
	local routeName myResult myRoute myOut n

	# Keep building dep trees for nodes we haven't included, add them recursively to our
	# output tree and don't worry about duplicates just yet...
        for (( n = 0 ; n <= ${#__INTERNAL__DEPS__REQ_N[@]}; ++n )) ; do
		if ! has "${__INTERNAL__DEPS__REQ_N[${n}]}" "${myRoute}"
		then
			myResult=$(buildDepTreeGeneric ${__INTERNAL__DEPS__REQ_N[${n}]})
			myRoute="${myRoute} ${myResult} ${__INTERNAL__DEPS__REQ_N[${n}]}"
		fi
        done

	# The last process can add duplicates. Remove them; FIFO.
	for point in ${myRoute}; do
		if ! has "${point}" "${myOut}"
		then
			myOut="${myOut} ${point}"
		fi
	done

#	echo "Corrected Route:${myRoute}"
#	echo "Corrected Route:${myOut}"
	echo ${myOut} # return
}
