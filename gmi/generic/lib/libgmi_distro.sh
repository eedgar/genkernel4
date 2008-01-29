#!/bin/sh
#
# Copyright 2008 Tim Yamin <plasm@roo.me.uk>
# Distributed under the terms of the GNU General Public License v2
#
# Functions library for detecting and performing distribution-specific
# fixups, if necessary.
#

# Take a guess at what distribution is installed.
#
# (Parameters)
# 1: Path to root mount point.
#
# (Return)
# "${distro_name}:${distro_version:-unknown}" or "unknown"
#
distro_detect() {
	local ROOT="${1}"

	# Gentoo
	if [ -f "${ROOT}"/etc/gentoo-release ]
	then
		echo 'gentoo:unknown'
		return
	fi

	# I give up...
	echo 'unknown'	
}

# Perform any fixups the distribution requires (e.g. mounting /sys or /proc)
#
# (Parameters)
# 1: Path to root mount point.
# 2: Output from distro_detect.
#
# (Returns nothing)
#
distro_perform_fixups() {
	local ROOT="${1}"
	local DISTRO="$(echo ${2} | cut -d: -f1)"
	local VERSION="$(echo ${2} | cut -d: -f2)"

	# FIXME
	# some distros need a /proc and /sys (Fedora, for example)
	# mkdir ${ROOTFS}/proc ${ROOTFS}/sys 2>/dev/null
	# mount -t proc proc ${ROOTFS}/proc 2>/dev/null
	# mount -t sysfs sysfs ${ROOTFS}/sys 2>/dev/null
	# and some /dev/ices
	# mkdir  ${ROOTFS}/dev 2>/dev/null
	# cp -a /dev/* ${ROOTFS}/dev 2>/dev/null
}
