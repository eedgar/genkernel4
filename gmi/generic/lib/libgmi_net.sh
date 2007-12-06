#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org> and 
#                Jean-Francois Richard <jean-francois@richard.name> 
# Distributed under the terms of the GNU General Public License v2
#
#
# Functions library for GMI scripts, related to networking
#


# Starts networking.  Uses the 'ip=' kernel parameter, with the format described
# in /usr/src/linux/Documentation/nfsroot.txt.
# 
# (No parameters)
#
setup_networking() {
	if [ -n "${IP}" ]
	then
		# From /usr/src/linux/Documentation/nfsroot.txt
		# ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>

		local client_ip=$(  echo ${IP} | cut -d':' -f1 )
		local server_ip=$(  echo ${IP} | cut -d':' -f2 )
		local gw_ip=$(      echo ${IP} | cut -d':' -f3 )
		local netmask=$(    echo ${IP} | cut -d':' -f4 )
		local hostname=$(   echo ${IP} | cut -d':' -f5 )
		local ethdev=$(     echo ${IP} | cut -d':' -f6 )
		local autoconf=$(   echo ${IP} | cut -d':' -f7 )

		# default device is eth0
		[ -z "${ethdev}" ] && ethdev="eth0"

		# if last param is dhcp, get the interface from <device>
		# and use udhcpc on it		
		if [ "${autoconf}" = "dhcp" ]
		then
			# Only 'dhcp' was on the line, the user did not
			# use the full '::::::dhcp'.  Must correct 'ethdev'
			[ "${ethdev}" = "dhcp" ] && ethdev="eth0"

			if [ -e /sbin/udhcpc ]
			then
				good_msg "Setting up networking on ${ethdev} (${autoconf})"
				chmod +x ${LIBGMI}/udhcp.sh # Make sure udhcpc can execute the script

				if /sbin/udhcpc --now -i ${ethdev} -s ${LIBGMI}/udhcp.sh \
				    | grep "FATAL"; then

				    assert "$?" "\t'ip=${IP}' setup failed" || return 1
				fi
			fi

		elif [ "${autoconf}" = "bootp" -o "${autoconf}" = "rarp" ]
		then
			good_msg "Using kernel IP configuration (${autoconf})"

		else
			good_msg "Setting up networking (manual config)"

			# busybox ifconfig crashes if we dont bring up the device first	
			# ifconfig ${ethdev} up > /dev/null 2>&1

			# If netmask isn't empty then format things correctly:
			[ -n "${netmask}" ] && netmask="netmask ${netmask}"

			ifconfig ${ethdev} ${client_ip} ${netmask} up # > /dev/null 2>&1
			assert "$?" "\t'ip=${IP}' setup failed" || return 1

			if [ -n "${gw_ip}" ]
			then
				route add default gw ${gw_ip} > /dev/null 2>&1
				assert "$?" "\tDefault gateway '${gw_ip}' setup failed"
			fi
		fi

		ifconfig lo up # > /dev/null 2>&1

		if [ -e /sbin/portmap ]
		then
			portmap &
		fi

		if [ -n "${NAMESERVER}" ]
		then
			echo "nameserver ${NAMESERVER}" > /etc/resolv.conf
		fi
	else
		return 0
	fi
}
