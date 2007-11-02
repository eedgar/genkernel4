#!/bin/bash

#TODO change to profile parameter ..
TMPDIR='/var/tmp/genkernel'
TODEBUGCACHE=false # Until an error occurs or DEBUGFILE is fully qualified.
TEMP="${TMPDIR}/$RANDOM.$$"

# Find another directory if we clash
while [ -e "${TEMP}" ]
do
    TEMP="${TMPDIR}/$RANDOM.$$"
done

#Internal flag to check if config parsing succeeded
__INTERNAL__CONFIG_PARSING_FAILED=false
