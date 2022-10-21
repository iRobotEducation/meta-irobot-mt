FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

# start haveged early in the boot process
INITSCRIPT_PARAMS_${PN} = "start 4 S ."

do_install_append() {
        # turn off verbosity in the haveged startup script
	sed -i -e 's, ${HAVEGED_BIN} -w 1024 -v 1, ${HAVEGED_BIN} -w 1024 -v 0,g' ${D}${sysconfdir}/init.d/haveged
}
