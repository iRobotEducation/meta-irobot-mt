require recipes-core/images/core-image-minimal.bb
require recipes-core/images/${MACHINE}/${MACHINE}-base-image.inc

EXTRA_IMAGE_FEATURES += " package-management "
NO_RECOMMENDATIONS_pn-base-image = "1"

# Add in the packages we actually use that were "recommended" before, but which are
# no longer installed since we're not installing "recommended" packages:
IMAGE_INSTALL += " \
	busybox-syslog \
	busybox-udhcpc \
	wpa-supplicant-cli \
	wpa-supplicant-passphrase \
	dbus \
	util-linux-mount \
	iptables-modules \
	kernel-module-x-tables \
	kernel-module-ip-tables \
	kernel-module-iptable-filter \
	kernel-module-iptable-nat \
	kernel-module-nf-defrag-ipv4 \
	kernel-module-nf-conntrack \
	kernel-module-nf-conntrack-ipv4 \
	kernel-module-nf-nat \
	kernel-module-ipt-masquerade \
	"
# We need update-rc.d to support installing the create-platform.ipk at runtime (in devmode)
# But, because we told Yocto that our rootfs is readonly (see `EXTRA_IMAGE_FEATURES` in
# conf/machine/sundial.conf), Yocto helpfully prevents "update-rc.d" from being included
# in the image.  We undo that helpfulness by removing "update-rc.d" from the list
# of packages Yocto declares as unneeded for readonly rootfs's.  (See image.bbclass and
# rootfs.py).
ROOTFS_RO_UNNEEDED_remove += "update-rc.d"
	
TOOLCHAIN_TARGET_TASK_append = " \
	argp-standalone-staticdev \
	curl-dev \
	libarchive-dev \
	libcurl \
	util-linux-dev \
	libogg-dev \
	libopus-dev \
	libopusfile-dev \
	alsa-lib-dev \
	${@oe.utils.conditional('ROBOT', "create3", "bluez5-dev", "", d)} \
	"

# irobot packages
IMAGE_INSTALL += " \
        ${@oe.utils.conditional('BUILD_TYPE', "release", "", "packagegroup-irobot-debug", d)} \
        packagegroup-irobot-irbt-connectivity \
        ${@oe.utils.conditional('ROBOT', "create3", "packagegroup-irobot-irbt-create3", "packagegroup-irobot-irbt-navigation", d)} \
        packagegroup-irobot-irbt-utils \
        packagegroup-irobot-oe-network \
        packagegroup-irobot-oe-utils \
"

IMAGE_INSTALL += "packagegroup-core-boot"
IMAGE_INSTALL += "packagegroup-core-ssh-dropbear"

inherit extrausers
EXTRA_USERS_PARAMS = "\
        useradd -P '' apps;\
        usermod -s /bin/sh apps; \
        "
