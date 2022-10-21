FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
	file://fstab \
	"

do_install_append() {
        install -d ${D}/mnt/system.prev
}

FILES_${PN} += "/mnt/*"
