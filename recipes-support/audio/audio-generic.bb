DESCRIPTION = "audio support for generic robots"
PRIORITY = "required"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "squashfs-tools-native zip-native"

S = "${WORKDIR}"
ROBOT = "generic"

inherit deploy

do_compile() {

    # for builds with ROBOT=generic, create a northamerican language pack with no audio files.
    # (audio files are not needed for a generic ROBOT build)
    # this language pack file is needed by the ubi-image recipe when is runs the ubinize command.
    mkdir -p ${S}/build/
    mkdir -p ${S}/packs/northamerica
    echo unknown > ${S}/packs/northamerica/lang_pack_name.txt
    mksquashfs ${S}/packs/northamerica ${S}/build/northamerica.squashfs-xz -noappend -no-xattrs -all-root -comp xz
    zip -qrj ${S}/${MACHINE}-${ROBOT}-squashfs-language_packs.zip  ${S}/build/northamerica.squashfs-xz
}

do_install() {
    install -d ${D}/opt/irobot/audio/languages
}

do_deploy () {
    mkdir -p ${DEPLOYDIR}/language/language_packs
    cp ${S}/build/northamerica.squashfs-xz ${DEPLOYDIR}/language/language_packs
    cp ${S}/${MACHINE}-${ROBOT}-squashfs-language_packs.zip ${DEPLOYDIR}/language/language_packs
}

addtask deploy after do_install

FILES_${PN} += "/opt/irobot/*"
