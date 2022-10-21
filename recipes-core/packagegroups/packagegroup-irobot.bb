# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "irobot base package group"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PR = "r15"
# I'm not sure what Frank wanted to do by assigning "${ROBOT}" to PV, perhaps it had
# something to do with the package version used when producing installable packages for
# different robots.  I am finding that it interfers with building code for Daredevil vs
# create3 (by changing ROBOT), so I am removing this.
#PV = "${ROBOT}"
OVERRIDES += ":${PRODUCT}"

PACKAGE_ARCH = "${MACHINE_ARCH}"
inherit packagegroup

PROVIDES = "${PACKAGES}"
PACKAGES += " \
	${PN}-irbt-connectivity \
	${PN}-irbt-navigation \
	${PN}-irbt-create3 \
	${PN}-irbt-utils \
	${PN}-oe-network \
	${PN}-oe-utils \
	${PN}-min \
	${PN}-test \
	${PN}-debug \
"

RDEPENDS_${PN}-irbt-utils = " \
	firewall \
	irbtsetup \
	libgpio \
	provision \
	stop-watchdog \
	version \
    coredumps-init \
    ts \
	ota-cleanup \
"

RDEPENDS_${PN}-oe-utils = " \
	alsa-utils-amixer \
	alsa-utils-aplay \
	alsa-utils-speakertest \
        audio-generic \
	coreutils \
	mt7688-utils \
	mtd-utils \
	mtd-utils-ubifs \
	${@oe.utils.conditional('BUILD_TYPE', 'profile', 'perf', '', d)} \
	sed \
	sudo \
	swupdate \
	${@oe.utils.conditional('BUILD_TYPE', 'profile', 'trace-cmd', '', d)} \
	u-boot-fw-utils \
	wireless-tools \
    xxd \
	${@oe.utils.conditional('BUILD_TYPE', 'profile', 'strace', '', d)} \
"

RDEPENDS_${PN}-oe-utils_append_linkit7688 = " \
	swconfig \
"

# flash space is limited on the linkit7688 board.
# remove packages not needed in linkit7688 firmware.
RDEPENDS_${PN}-oe-utils_remove_linkit7688 = " \
	audio \
	wireless-tools \
"

RDEPENDS_${PN}-oe-network = " \
        bridge-utils \
	crda \
	iw \
	ntp-startup \
	wpa-supplicant \
"

RDEPENDS_${PN}-irbt-connectivity = " \
	curl \
	hostapd \
	libarchive \
	libcurl \
	util-linux-libuuid \
	wpa-supplicant \
"

# flash space is limited on the linkit7688 board.
# remove packages not needed in linkit7688 firmware.
RDEPENDS_${PN}-irbt-connectivity_remove_linkit7688 = " \
        ${@oe.utils.conditional('ROBOT', 'generic', '', 'connectivity', d)} \
"
RDEPENDS_${PN}-oe-network_remove_linkit7688 = " \
	crda \
"

RDEPENDS_${PN}-irbt-navigation = " \
	libopus \
	libopusfile \
	libpcap \
	opus-tools \
"

# We omit 'create-platform' from the -irbt-create3 package group as an optimization.
# Don't bother building create-platform unless we are building for the Create3
# robot.  We use bb.utils.contains_any() in the -irbt-navigation package group for
# a similar reason - Don't bother building 'cleantrack' when we are building for
# the create3 robot.
RDEPENDS_${PN}-irbt-create3 = " \
	libopus \
	libopusfile \
	libpcap \
	opus-tools \
	avahi-daemon \
	bluez5 \
	socat \
"

RDEPENDS_${PN}-debug = " \
"

RDEPENDS_${PN}-test = " \
	iperf3 \
	picocom \
	alsa-utils \
	autoconf \
	automake \
	bc \
	bison \
	binutils \
	bzip2 \
	dhrystone \
	ethtool \
	file \
	findutils \
	gcc \
	gdb \
	git \
	i2c-tools \
	iperf3 \
	ldd \
	libtool \
	make \
	memtester \
	minicom \
	parted \
	pciutils \
	python-numpy \
	rsync \
	screen \
	strace \
	stress \
	tcpdump \
	usbutils \
	whetstone \
	valgrind \
"

RDEPENDS_${PN}-min = " \
	base-files \
	base-passwd \
"
ALLOW_EMPTY_${PN} = "1"

