FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

do_install_append() {
        # only base64.coreutils is needed from usr.  remove all the other files
	cd ${D}/usr
	find . ! -name 'base64.coreutils' -type f -exec rm -f {} +
	lnr ${D}/usr/bin/base64.coreutils  ${D}/usr/bin/base64
        # only cp.coreutils is needed from bin.  remove all the other files
	cd ${D}/bin
	find . ! -name 'cp.coreutils' -type f -exec rm -f {} +
}

ALTERNATIVE_${PN} = "cp"
ALTERNATIVE_${PN}-doc = ""

FILES_${PN}="/bin/* /usr/*"
