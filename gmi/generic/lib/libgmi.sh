#!/bin/sh
# Copyright 2006 Eric Edgar <rocket@gentoo.org>, 
#                Tim Yamin <plasmaroo@gentoo.org> and 
#                Jean-Francois Richard <jean-francois@richard.name> 
# Distributed under the terms of the GNU General Public License v2
#
#
# Loads all GMI functions libraries
#

. /etc/initrd.defaults

for lib in ${LIBGMI}/libgmi_*
do
	. ${lib}
done
