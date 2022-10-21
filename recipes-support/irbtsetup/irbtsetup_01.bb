SUMMARY = "iRobot board setup "
LICENSE="GPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = " \
           file://irbtsetup \
"

PR = "r7"

inherit autotools update-rc.d pkgconfig

INITSCRIPT_NAME = "irbtsetup"
INITSCRIPT_PARAMS = "defaults 55"

do_compile () {
}

do_install () {
        install -d ${D}${sysconfdir}/init.d
        install -m 0755 ${WORKDIR}/irbtsetup ${D}${sysconfdir}/init.d/
}

FILES_${PN} += "${sysconfdir}/*"

