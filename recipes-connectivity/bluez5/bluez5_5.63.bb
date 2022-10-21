# With the exception of bluez5_%.bbappend and the files referenced within that file.
# The files in this directory were copied from commit ID 92bb6f72ceb39c99e5c93c0a99b70fb210233acb
# of https://git.yoctoproject.org/git/poky and modified slightly to work with
# Yocto 2.6.  Specifically, we had to change things like:
#
#    RPROVIDES_${PN} += "bluez-hcidump"
#
# to be
#
#   RPROVIDES:${PN} += "bluez-hcidump"
#
# in order to work with the older version of Bitbake that we use.
require bluez5.inc

SRC_URI[sha256sum] = "9349e11e8160bb3d720835d271250d8a7424d3690f5289e6db6fe07cc66c6d76"

# These issues have kernel fixes rather than bluez fixes so exclude here
CVE_CHECK_WHITELIST += "CVE-2020-12352 CVE-2020-24490"

# noinst programs in Makefile.tools that are conditional on READLINE
# support
NOINST_TOOLS_READLINE ?= " \
    ${@bb.utils.contains('PACKAGECONFIG', 'deprecated', 'attrib/gatttool', '', d)} \
    tools/obex-client-tool \
    tools/obex-server-tool \
    tools/bluetooth-player \
    tools/obexctl \
    tools/btmgmt \
"

# noinst programs in Makefile.tools that are conditional on TESTING
# support
NOINST_TOOLS_TESTING ?= " \
    emulator/btvirt \
    emulator/b1ee \
    emulator/hfp \
    peripheral/btsensor \
    tools/3dsp \
    tools/mgmt-tester \
    tools/gap-tester \
    tools/l2cap-tester \
    tools/sco-tester \
    tools/smp-tester \
    tools/hci-tester \
    tools/rfcomm-tester \
    tools/bnep-tester \
    tools/userchan-tester \
"

# noinst programs in Makefile.tools that are conditional on TOOLS
# support
NOINST_TOOLS_BT ?= " \
    tools/bdaddr \
    tools/avinfo \
    tools/avtest \
    tools/scotest \
    tools/amptest \
    tools/hwdb \
    tools/hcieventmask \
    tools/hcisecfilter \
    tools/btinfo \
    tools/btsnoop \
    tools/btproxy \
    tools/btiotest \
    tools/bneptest \
    tools/mcaptest \
    tools/cltest \
    tools/oobtest \
    tools/advtest \
    tools/seq2bseq \
    tools/nokfw \
    tools/create-image \
    tools/eddystone \
    tools/ibeacon \
    tools/btgatt-client \
    tools/btgatt-server \
    tools/test-runner \
    tools/check-selftest \
    tools/gatt-service \
    profiles/iap/iapd \
    ${@bb.utils.contains('PACKAGECONFIG', 'btpclient', 'tools/btpclient', '', d)} \
"
