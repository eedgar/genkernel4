#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org> and 
#                Jean-Francois Richard <jean-francois@richard.name> 
# Distributed under the terms of the GNU General Public License v2
#
#
# Functions library for GMI scripts, related to kernel configuration
# and modules
#


# Change kernel message verbosity to quiet
#
# (No parameters)
#
quiet_kmsg() {
	# if QUIET is set make the kernel less chatty
	[ -n "$QUIET" ] && echo '0' > /proc/sys/kernel/printk
}


# Change kernel message verbosity to verbose
#
# (No parameters)
#
verbose_kmsg() {
	# if QUIET is set make the kernel less chatty
	[ -n "$QUIET" ] && echo '6' > /proc/sys/kernel/printk
}


# Test whether we're running on UML or not
#
# (No parameters)
#
is_uml_sys() {
        grep -qs 'UML' /proc/cpuinfo
        return $?
}


# Load modules, except if there is a noMODNAME command-line option
#
# (No parameters)
#
load_modules() {
	if [ -d '/lib/modules' ]
	then
		good_msg 'Scanning module classes'
		cd /etc/modules
		for i in *
		do
			if has "no$i" $CMDLINE " "
			then
				dbg_msg "\tCMDLINE: no$i detected. Skipping load of $i class"
			else
				good_msg "\t$i class modules"
				for j in $(cat $i)
				do
					module_location=$(find /lib/modules/`uname -r` -name ${j}*)
					if [ -n "${module_location}" ]
					then
						if ! has $j $LOADED_MODULES " "
						then
							dbg_msg "\t\t$j module"
							#insmod "${module_location}"
							modprobe $j 2> /dev/null 1>&2
							LOADED_MODULES="${LOADED_MODULES} $j"
						fi
					fi
				done
			fi
		done
	fi

	[ -n "${SCANDELAY}" ] && sleep ${SCANDELAY} 
}


# Loads and start UnionFS, create appropriate directories as needed
#
# (No parameters)
#
setup_unionfs() {
	if [ "${USE_UNIONFS}" != "yes" ]
	then
		local module_location
		[ -d /lib/modules ] && module_location=$(find /lib/modules -name unionfs.ko)
		grep -qs 'unionfs' /proc/filesystems

		if [ -n "${module_location}" -o "$?" = 0 ]
		then
			good_msg "Enabling UnionFS support"
			[ -n "${module_location}" ] && insmod "${module_location}"
			dbg_msg "Mounting the base tmpfs for unionfs"
			mkdir ${UNIONS}/.base
			mount -t tmpfs tmpfs ${UNIONS}/.base
			mount -t unionfs -o dirs=${UNIONS}/.base=rw unionfs ${ROOTFS}
			USE_UNIONFS="yes"
			USE_UNIONFSALIKE="yes"
		else
			dbg_msg "The unionfs.ko module does not exist, unionfs disabled."
		fi
	fi
}

setup_unionfsalike() {
	# Use aufs if available; otherwise let's try unionfs
	grep -qs 'aufs' /proc/filesystems
	if [ "$?" -eq 0 ]
	then
		good_msg "Enabling aufs support"
		USE_AUFS="yes"
		USE_UNIONFSALIKE="yes"
	else
		setup_unionfs
	fi
}

# Detect SBP-2 devices
#
# (No parameters)
#
detect_sbp2_devices() {
	# http://www.linux1394.org/sbp2.php
  
	# /proc
	# /proc/scsi/sbp2/0, /proc/scsi/sbp2/1, etc.
	#
	# You may manually add/remove SBP-2 devices via the procfs with 
	# add-single-device <h> <b> <t> <l> or 
	# remove-single-device <h> <b> <t> <l>, where:
	#
	#
	# <h> = host (starting at zero for first SCSI adapter)
	# <b> = bus (normally zero)
	# <t> = target (starting at zero for first SBP-2 device)
	# <l> - lun (normally zero) 
	#
	# e.g. To manually add/detect a new SBP-2 device
	# 	echo "scsi add-single-device 0 0 0 0" > /proc/scsi/scsi
	# e.g. To manually remove a SBP-2 device after it's been unplugged
	# 	echo "scsi remove-single-device 0 0 0 0" > /proc/scsi/scsi
	# e.g. To check to see which SBP-2/SCSI devices are currently registered
	# 	cat /proc/scsi/scsi 

	[ -e /proc/scsi/scsi ] && echo 'scsi add-single-device 0 0 0 0' > /proc/scsi/scsi
}
