#
# This is a work in progress.
#

Summary: Flexible platform for generating kernel, initramfs images
Name: genkernel
License: GPL
Version: 4.0.0
Release: 1
Group: System/Boot
Packager: Jean-Francois Richard <trucker@genkernel.org>
URL: http://genkernel.org
Source: http://genkernel.org/releases/genkernel-4.0.0.tar.gz
BuildRequires: asciidoc, xsltproc, docbook-xml, docbook-xsl

%description
Genkernel is a platform designed to help users build kernel and
initramfs images.  It provides several configuration options to
support particular hardware setups and sports a flexible initramfs
script library to allow booting from many types of devices.

Genkernel's initramfs supports a variety of systems such as LVM2,
EVMS, aufs, UnionFS, LUKS, as well as various netbooting options.  It
can also provide LiveCD-style autoconfiguration of devices using
kernel modules with special parameters.

%prep
%setup -q

%build
# Build the doc
cd doc; make; cd -


%install
GK_HOME=/usr/share/genkernel

rm -rf $RPM_BUILD_ROOT

# Simply copy the stuff
cp -r * ${RPM_BUILD_ROOT}/$(GK_HOME)

# And remove some from the result
rm -rf ${RPM_BUILD_ROOT}/$(GK_HOME)/debian
rm -rf ${RPM_BUILD_ROOT}/$(GK_HOME)/doc
chmod a+x ${RPM_BUILD_ROOT}/$(GK_HOME)/genkernel

# Convenient symlink
ln -s $(GK_HOME)/genkernel ${RPM_BUILD_ROOT}/usr/bin


%clean
/bin/rm -rf $RPM_BUILD_ROOT


%changelog
* Tue Nov  13 2007 Jean-Francois Richard <trucker@genkernel.org> 4.0.0-1
- new upstream version


