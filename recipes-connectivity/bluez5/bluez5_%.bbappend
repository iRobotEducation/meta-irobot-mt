FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://main.conf \
    file://bluetooth.conf \
"

PACKAGECONFIG = " \
    deprecated \
    tools \
    readline \
"

# Somehow PACKAGECONFIG += "readline" means "enable the bluetoothctl" application.  Huh?

localstatedir="/var/volatile"

FILES_${PN}-noinst-tools_remove = "${bindir}/btmgmt"

do_install_append() {
    install -d ${D}/${sysconfdir}/bluetooth
    install -m 0755 ${WORKDIR}/main.conf ${D}${sysconfdir}/bluetooth/main.conf

    install -m 0755 ${WORKDIR}/bluetooth.conf ${D}${sysconfdir}/dbus-1/system.d/bluetooth.conf

    # Free up a tiny amount of space (504K, uncompressed)
    rm ${D}${bindir}/hcidump
}
