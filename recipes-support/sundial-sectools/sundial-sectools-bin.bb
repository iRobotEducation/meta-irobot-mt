DESCRIPTION = "Sundial sectools, binary only"
LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Proprietary;md5=0557f9d92cf58f2ccdd50f62f8ac0b28"

SRC_URI = "file://mtal-extractor \
	   file://extract-rtcs-key \
	  "
DEPENDS += "openssl keyutils"

do_install () {
        install -d ${D}${bindir}
	install -m 0755 ${WORKDIR}/mtal-extractor ${D}${bindir}
	install -m 0755 ${WORKDIR}/extract-rtcs-key ${D}${bindir}
}

PACKAGES =+ "${PN}-extract-rtcs-key"
FILES_${PN}-extract-rtcs-key += "${bindir}/extract-rtcs-key"

PACKAGES =+ "${PN}-mtal-extractor"
FILES_${PN}-mtal-extractor += "${bindir}/mtal-extractor"
