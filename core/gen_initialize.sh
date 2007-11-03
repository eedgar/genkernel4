#!/bin/bash

TMPDIR='/tmp'
TODEBUGCACHE=false # Until an error occurs or DEBUGFILE is fully qualified.
TEMP="${TMPDIR}/genkernel.$RANDOM.$$"

# Find another directory if we clash
while [ -e "${TEMP}" ]
do
    TEMP="${TMPDIR}/genkernel.$RANDOM.$$"
done

#Internal flag to check if config parsing succeeded
__INTERNAL__CONFIG_PARSING_FAILED=false
