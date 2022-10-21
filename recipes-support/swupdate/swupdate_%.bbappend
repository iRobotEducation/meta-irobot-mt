FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
        file://fragment.cfg \
        file://hwrevision \
        file://swupdate \
        file://ota_install.sh \
        "

do_install_append() {
	install -d ${D}${sysconfdir}
	install -m 0755 ${WORKDIR}/hwrevision ${D}${sysconfdir}
        install -d ${D}${bindir}
        install -m 0755 ${WORKDIR}/ota_install.sh ${D}${bindir}/ota_install.sh
        # use the ota_install.sh file for language installs
        lnr ${D}${bindir}/ota_install.sh ${D}${bindir}/language_install.sh
}

FILES_${PN} += "${sysconfdir}/* ${bindir}/*"

DEPENDS += "opensource-keys-native openssl-native"
RDEPENDS_${PN} += "openssl-bin sundial-sectools-bin-mtal-extractor"
SRC_URI += "file://0001-Allow-sha256-attribute-to-be-spelled-sha256sum.patch \
            file://0002-Add-support-for-signature-check-optional-command-lin.patch \
            file://0003-Add-support-for-hash-optional-command-line-option.patch \
            file://0004-Add-support-for-query-attribute-command-line-option.patch \
            file://0005-Add-support-for-quiet-command-line-option.patch \
            file://0006-swupdate-fix-ubi-probe-failures-on-creating-volume.patch \
            file://0007-swupdate-add-sleep-1-sec-to-avoid-probe-error.patch \
            "
