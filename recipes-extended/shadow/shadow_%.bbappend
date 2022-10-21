FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

do_install_append() {
        # add /sbin and /usr/sbin to the path for non-root users
	sed  -i 's:^ENV_PATH.*:ENV_PATH        PATH=/sbin\:/bin\:/usr/sbin\:/usr/bin:g' ${D}${sysconfdir}/login.defs
}

