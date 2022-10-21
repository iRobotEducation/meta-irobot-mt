# Recipe file is from meta-embedded
#   repo    :   git://git.openembedded.org/meta-openembedded
#   branch  :   master
SUMMARY = "Multiplatform C library implementing the SSHv2 and SSHv1 protocol"
HOMEPAGE = "http://www.libssh.org"
SECTION = "libs"
LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=dabb4958b830e5df11d2b0ed8ea255a0"

# PR will contain "<local_revision_starting_from_0>"

PR = "1"

DEPENDS = "openssl"

SRC_URI = "git://git.libssh.org/projects/libssh.git;branch=stable-0.8"
SRCREV = "04685a74df9ce1db1bc116a83a0da78b4f4fa1f8"

S = "${WORKDIR}/git"

inherit cmake

PACKAGECONFIG ??=""
PACKAGECONFIG[gssapi] = "-DWITH_GSSAPI=1, -DWITH_GSSAPI=0, krb5, "

ARM_INSTRUCTION_SET_armv5 = "arm"

EXTRA_OECMAKE = " \
    -DWITH_OPENSSL=1 \
    -DWITH_PCAP=OFF \
    -DWITH_SFTP=OFF \
    -DWITH_ZLIB=OFF \
    -DWITH_SERVER=OFF \
    -DWITH_DEBUG_CALLTRACE=OFF \
    -DWITH_EXAMPLES=OFF \
    -DLIB_SUFFIX=${@d.getVar('baselib').replace('lib', '')} \
    "

do_configure_prepend () {
    # Disable building of examples
    sed -i -e '/add_subdirectory(examples)/s/^/#DONOTWANT/' ${S}/CMakeLists.txt \
        || bbfatal "Failed to disable examples"
}

TOOLCHAIN = "gcc"
