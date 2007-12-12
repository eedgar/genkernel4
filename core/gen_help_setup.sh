#!/bin/bash
# This file stores the default genkernel settings

#  GROUP -> OPTION -> DATA (Boolean):[DEFAULT] -> Allow no'X' (Boolean) -> DESCRIPTION -> Optional (handler function)

## Debug
__register_config_option 'Debug' 'debuglevel' 'true' 'false' 'Debug verbosity level'
profile_set_key debuglevel '1' 'system'

__register_config_option 'Debug' 'debugfile'  'true' 'false' 'Output file for debug info'

## Internals
__register_config_option 'Internals' 'arch' 'true' 'false' 'Force to arch instead of autodetecting.'
__register_config_option 'Internals' 'kernel-arch' 'true' 'false' 'Force to arch instead of autodetecting. (Kernel-only)'
__register_config_option 'Internals' 'utils-arch' 'true' 'false' 'Force to arch instead of autodetecting. (Utils only)'
__register_config_option 'Internals' 'callback'	'true' 'false' 'Run the specified arguments after the kernel and modules have been compiled.'
__register_config_option 'Internals' 'cachedir' 'true' 'false' 'Override the default cache location.'
__register_config_option 'Internals' 'tempdir' 'true' 'false' "Location of Genkernel's temporary directory."

__register_config_option 'Internals' 'makeopts' 'true' 'false' 'Global make options.'
__register_config_option 'Internals' 'profile' 'true' 'false' 'Use specified internal profile. eg (xen, um, x86)'
__register_config_option 'Internals' 'profile-load' 'true!m' 'false' 'Use specified profile(s).' 'config_profile_read'
__register_config_option 'Internals' 'profile-dump' 'false' 'false' 'Dump the current profile to the cmdline.'
__register_config_option 'Internals' 'usecolor' 'false' 'true' 'Use colored output.'
profile_set_key usecolor true 'system'
__register_config_option 'Internals' 'help' 'false' 'false' '' # Hidden.

## Cross Compilation
__register_config_option 'Cross compile' 'cross-compile' 'true' 'false' 'Cross compiler settings (Overrides kernel-cross-compile and utils-cross-compile)'
__register_config_option 'Cross compile' 'kernel-cross-compile' 'true' 'false' 'Kernel cross compiler settings.'
__register_config_option 'Cross compile' 'utils-cross-compile' 'true' 'false' 'Utilities cross compiler settings.'
__register_config_option 'Cross compile' 'internal-uclibc' 'false' 'true' 'Build using a uclibc cross compiling environment.  Will take a long time.'


## Kernel Config
__register_config_option 'Kernel Configuration' 'kernel-config' 'true' 'false' 'Kernel configuration file to use for compilation.'
__register_config_option 'Kernel Configuration' 'running-kernel-config' 'true' 'false' 'Use /proc/config.gz if found for the kernel config.'
__register_config_option 'Kernel Configuration' 'force-config' 'false' 'true' 'Turn on any config options genkernel deems mandatory.'
profile_set_key force-config false 'system'
__register_config_option 'Kernel Configuration'	'menuconfig'	 'false' 'true'	 'Run menuconfig after oldconfig.'
profile_set_key 'menuconfig' false 'system'

__register_config_option 'Kernel Configuration'	'save-config' 'false' 'true' "save the configuration to /etc/kernels."
profile_set_key 'save-config' false 'system'

__register_config_option 'Kernel Configuration'	'oldconfig'	 'false' 'true' 'Run oldconfig.'
profile_set_key 'oldconfig' false 'system'

__register_config_option 'Kernel Configuration'	'config'	 'false' 'true' 'Run config after oldconfig.'
__register_config_option 'Kernel Configuration'	'gconfig'	 'false' 'true' 'Run gconfig after oldconfig.'
__register_config_option 'Kernel Configuration'	'xconfig'	 'false' 'true' 'Run xconfig after oldconfig.'
__register_config_option 'Kernel Configuration' 'mrproper'		'false' 'true'	'Run "make mrproper" before compilation.'
__register_config_option 'Kernel Configuration' 'clean'		'false'	'true'	'Run "make clean" before compilation.'
__register_config_option 'Kernel Configuration' 'internal-initramfs' 'false' 'true' 'Compile initramfs-internally'
profile_set_key internal-initramfs false 'system'
__register_config_option 'Kernel Configuration' 'kernel-tree'   'true' 'false' 'Location of kernel sources.'
profile_set_key kernel-tree '/usr/src/linux'
__register_config_option 'Kernel Configuration' 'kbuild-output'   'true' 'false' 'Location to use for Kbuild output.'
__register_config_option 'Kernel Configuration' 'kernel-name' 'true' 'false' 'Tag the kernel and initramfs with a name; if not defined the option defaults to "genkernel".'
__register_config_option 'Kernel Configuration' 'kernel-make-directive' 'true' 'false' 'Override the make directive used to build the kernel'
__register_config_option 'Kernel Configuration' 'kernel-binary' 'true' 'false' 'Location of the kernel binary created inside the tree'
profile_set_key kernel-name genkernel 'system'

## Initramfs options
__register_config_option 'Initramfs' 'single-cpio' 'false' 'true' "Single compressed cpio output."
profile_set_key single-cpio false 'system'
__register_config_option 'Initramfs' 'gmi' 'false' 'true' "Disable genkernel's initramfs scripts"
profile_set_key gmi true 'system'

__register_config_option 'Initramfs' 'busybox' 'false' 'true' 'Add busybox to the initramfs'
profile_set_key busybox true 'system'
__register_config_option 'Initramfs' 'busybox-config' 'true' 'false' 'busybox config file to use'
__register_config_option 'Initramfs' 'busybox-menuconfig' 'false' 'true' 'Run menuconfig on busybox config file'

__register_config_option 'Initramfs' 'dmraid' 'false' 'true' 'Include DMRAID support.'
__register_config_option 'Initramfs' 'evms2' 'false' 'true' 'Include EVMS2 support.'
__register_config_option 'Initramfs' 'lvm2' 'false' 'true' 'Include LVM2 support.'
__register_config_option 'Initramfs' 'e2fsprogs' 'false' 'true' 'Include e2fsprogs blkid support.'
__register_config_option 'Initramfs' 'disklabel' 'false' 'true' 'Include disk label and uuid support in your initramfs.'
__register_config_option 'Initramfs' 'portmap' 'false' 'true' 'Include portmap inside the initramfs.'
__register_config_option 'Initramfs' 'open-iscsi' 'false' 'true' 'Include open-iscsi inside the initramfs.'
__register_config_option 'Initramfs' 'aoetools' 'false' 'true' 'Include aoetools inside the initramfs.'
__register_config_option 'Initramfs' 'luks' 'false' 'true' 'Include cryptsetup-luks inside the initramfs.'

__register_config_option 'Initramfs' 'kernel-modules'   'true!m' 'false' 'Add or subtract kernel modules from the initramfs. --kernel-module="GROUP:module -module"' 'cmdline_modules_register'
__register_config_option 'Initramfs' 'kernel-modules-cpio' 'false' 'true' 'Add kernel modules to the initramfs'
profile_set_key kernel-modules-cpio true 'system'

__register_config_option 'Initramfs' 'initramfs-overlay' 'true' 'false' 'Directory structure to include in the initramfs.'
__register_config_option 'Initramfs' 'external-cpio' 'true!m' 'false' 'Include an external cpio file.'
__register_config_option 'Initramfs' 'linuxrc' 'true' 'false' 'Use a user specified linuxrc.'

__register_config_option 'Initramfs' 'keymap-auto' 'false' 'true' 'Force keymap selection at boot.'
__register_config_option 'Initramfs' 'gensplash' 'false' 'true' 'Include gensplash support.'
__register_config_option 'Initramfs' 'gensplash-res' 'true' 'false' 'Gensplash resolutions to include; this is passed to splash_geninitramfs in the "-r" flag.'
__register_config_option 'Initramfs' 'gensplash-theme' 'true' 'false' 'Gensplash theme to include.'
## Catalyst Init Internals
__register_config_option 'Initramfs' 'bladecenter' 'false' 'true' '' # Used by catalyst internally, hide option; 'Enables extra pauses for IBM Bladecenter CD boots.'


## ALL options
__register_config_option '"all::" target' 'initramfs' 'false' 'true' 'Build a initramfs'
profile_set_key initramfs true 'system'

## Installation options
__register_config_option 'Install' 'install-to-prefix' 'true' 'false' 'Destination prefix for initramfs, kernel and modules; default /.'
profile_set_key install-to-prefix '/' 'system'

__register_config_option 'Install' 'setgrub' 'false' 'true' 'Setup the grub.conf file'
profile_set_key setgrub false 'system'

__register_config_option 'Install' 'links' 'true' 'true' 'Create symbolic links to the generated kernel and/or initramfs'
profile_set_key links false 'system'

__register_config_option 'Install' 'mountboot' 'false' 'true' 'Mount /boot automatically.'
profile_set_key mountboot true 'system'

__register_config_option 'Install' 'bootdir' 'true' 'false' 'Location of the boot-directory; default /boot.'
profile_set_key bootdir '/boot' 'system'
