FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
        file://read-only-rootfs-hook.sh.irobot \
        file://rcS \
        file://persistent_setup.sh \
        file://mount-copybind \
        file://00_core \
        file://urandom-defaults \
        file://overlay.sh \
"

do_configure_append () {
        # comment out kill, was causing immediate shutdowns at boot time
        sed -i -e 's,^kill -USR1 1,# kill -USR1 1,g' ${S}/mountall.sh
}


do_install_append() {
        install -d ${D}/data/defaults
        install -d ${D}${sysconfdir}/init.d/
	install -m 0755 ${WORKDIR}/read-only-rootfs-hook.sh.irobot ${D}${sysconfdir}/init.d/read-only-rootfs-hook.sh
        install -d ${D}${sysconfdir}/default/volatiles
        install -m 0755 ${WORKDIR}/rcS ${D}${sysconfdir}/default/rcS
        install -m 0755 ${WORKDIR}/00_core ${D}${sysconfdir}/default/volatiles
        install -m 0755 ${WORKDIR}/urandom-defaults ${D}${sysconfdir}/default/urandom
        install -d ${D}${bindir}/
	install -m 0755 ${WORKDIR}/persistent_setup.sh ${D}${bindir}/
	install -m 0755 ${WORKDIR}/overlay.sh ${D}${bindir}/
        install -d ${D}${sbindir}/
	install -m 0755 ${WORKDIR}/mount-copybind ${D}${sbindir}/
        install -d ${D}/opt/irobot/bin
        install -d ${D}/opt/irobot/audio
        install -d ${D}/opt/irobot/firmware
        install -d ${D}/opt/irobot/logs
        install -d ${D}/opt/irobot/persistent
	# need save-rtc to run at shutdown. currently on runs at startup.
	# remove the default install, then configure it to run at both
	# startup and shutdown
	update-rc.d -f -r ${D} save-rtc.sh remove
	update-rc.d -r ${D} save-rtc.sh defaults 25 25
	update-rc.d -f -r ${D} urandom remove
	# urandom needs to start earlier in the boot process so that higher entropy
	# is available sooner for other boot scripts
	update-rc.d -r ${D} urandom start 30 S 0 6 .
}

FILES_${PN} += "${sysconfir}/init.d/* /data /opt/irobot/* ${bindir}/* ${sbindir}/*"
