#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org>, 
#                Jean-Francois Richard <jean-francois@richard.name> and 
#                Donnie Berkholz <dberkholz@gentoo.org>
#
# Copyright 2004 Vagrant Cascadian <vagrant@freegeek.org> and 
#                Jonas Smedegaard <dr@jones.dk>
#
# Distributed under the terms of the GNU General Public License v2
# Script called by udhcpc to set up the networking given some variables
#

initrd_defaults="/etc/initrd.defaults"

. ${initrd_defaults}
. "${LIBGMI}/libgmi.sh"

# Name the parameters
action="${1}"

RESOLV_CONF="/etc/resolv.conf"
[ -z "${1}" ] && bad_msg "Error: should be called from udhcpc" && exit 1
[ -n "${broadcast}" ] && BROADCAST="broadcast ${broadcast}"
[ -n "${subnet}" ] && NETMASK="netmask ${subnet}"

case "${1}" in
	renew|bound )
		/sbin/ifconfig ${interface} ${ip} ${BROADCAST} ${NETMASK}

		if [ -n "${router}" ]
		then
			dbg_msg "Deleting routers"
			while route del default gw 0.0.0.0 dev ${interface} 2> /dev/null; do
				:
			done

			for i in ${router} ; do
				route add default gw ${i} dev ${interface}
			done
		fi

		echo -n > ${RESOLV_CONF}
		[ -n "${domain}" ] && echo search ${domain} >> ${RESOLV_CONF}

		for entry in ${dns}
		do
			dbg_msg adding dns ${entry}
			echo nameserver ${entry} >> ${RESOLV_CONF}
		done

		# Save info for later use. This allows for multiple interfaces because
		# interface/ip will always come in pairs. Read interface, next line
		# is always the ip.
		echo "interface=\"${interface}\"" >> ${initrd_defaults}
		echo "ip=\"${ip}\"" >> ${initrd_defaults}
		if [ -n "${domain}" ]
		then
			echo "domain=\"${domain}\"" >> ${initrd_defaults}
		fi

		# For diskless NFS clients
		# This code is adapted from network_script in Debian's initrd-netboot
		if [ -n "${rootpath}" ]
		then
			nfspath="$(echo $rootpath | cut -d : -f2)"
			echo "nfspath=\"${nfspath}\"" >> ${initrd_defaults}
			if [ -n "$(echo $rootpath | grep :)" ]
			then
				x="$(echo $rootpath | cut -d : -f1)"
				if [ "$x" != "$nfspath" ]
				then
					nfsserver="$x"
					echo "nfsserver=\"${nfsserver}\"" >> ${initrd_defaults}
				fi
			fi
		fi
		;;
	deconfig )
		# remove the configuration of an interface
		/sbin/ifconfig ${interface} 0.0.0.0
		;;
esac
