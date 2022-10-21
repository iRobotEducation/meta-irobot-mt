# Create a separate keyutils-bin package that contains the executables
# installed by keyutils.  We only want to link against libkeyutils.so,
# so we don't include the keyutils-bin package in our build.

PACKAGES =+ "${PN}-bin"
FILES_${PN}-bin += "${base_bindir} ${base_sbindir} ${sysconfdir} ${datadir}"
