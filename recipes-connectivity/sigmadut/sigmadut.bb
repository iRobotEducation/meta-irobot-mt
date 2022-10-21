DESCRIPTION = "sigma tools"
PRIORITY = "required"
LICENSE="GPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"
SECTION = "console/utils"

PACKAGE_ARCH="${MACHINE_ARCH}"
PR = "r1"

SRC_URI = " \
          file://sigma_dut.tar.gz \
	  file://0001-fix-cross-compile.patch \
	  file://0002-use-usr-sbin.patch \
	  file://0003-mod-strcpy.patch \
"

S = "${WORKDIR}/sigma_dut_v9.0.0"

do_compile_prepend() {
     # remove stale objects that are in the tar file
     rm -f ${S}/lib/*.a
     rm -f ${S}/lib/*.o
     rm -f ${S}/ca/*.o
     rm -f ${S}/ca/*.o
     rm -f ${S}/dut/*.o
     rm -f ${S}/ca/wfa_ca
     rm -f ${S}/dut/wfa_dut
}

do_install() {
     install -d ${D}${sysconfdir}/WfaEndpoint
     install -m 0644 ${S}/wfa_cli.txt ${D}${sysconfdir}/WfaEndpoint
     install -d ${D}${sbindir}
     install -m 0755 ${S}/ca/wfa_ca ${D}${sbindir}/
     install -m 0755 ${S}/dut/wfa_dut ${D}${sbindir}/
     install -m 0755 ${S}/scripts/wfa_test_cli.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/wfaping.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/wfaping6.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/updatepid.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/stoping.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/gpstats.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/getpstats.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/getpid.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/getipconfig.sh ${D}${sbindir}/
     install -m 0755 ${S}/scripts/arp_neigh_loop ${D}${sbindir}/
}

FILES_${PN} += "${sbindir}/* ${sysconfdir}/WfaEndpoint/*"
