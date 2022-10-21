DESCRIPTION = "Generate firmware SWU image"
SECTION = ""

LICENSE="GPL-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

inherit irobot-version

# Add all local files to be added to the SWU
# sw-description must always be in the list.
SRC_URI = " \
    file://sw-description \
    file://swupdate-install.sh \
    "

DEPENDS += "openssl-native opensource-keys-native"

# images to build before building swupdate image
IMAGE_DEPENDS = "base-image firmware-fitimage"
IMAGE_NAME = "${MACHINE}-${BASENAME}"
IMAGE_LINK_NAME = "${MACHINE}-${ROBOT}"

# images and files that will be included in the .ota image
SWUPDATE_IMAGES = "base-image-${MACHINE}.squashfs-xz fitImage"

# a deployable image can have multiple format, choose one
SWUPDATE_IMAGES_FSTYPES[base-image] = ".img"
SWUPDATE_IMAGES_FSTYPES[fitImage] = ""

SWUPDATE_IMAGES_NOAPPEND_MACHINE[base-image-sundial.squashfs-xz] = "1"
SWUPDATE_IMAGES_NOAPPEND_MACHINE[base-image-showboat.squashfs-xz] = "1"
SWUPDATE_IMAGES_NOAPPEND_MACHINE[fitImage] = "1"
SWUPDATE_IMAGES_NOAPPEND_MACHINE[swupdate-install.sh] = "1"

SWUPDATE_SIGNING = "CUSTOM"
SWUPDATE_SIGN_TOOL = "openssl dgst -sha256 -sign ${STAGING_DIR_NATIVE}${datadir}/keys/C3OpenSource-CodeSigningKey.pri.key -out ${S}/sw-description.sig ${S}/sw-description"

FIRMWARE_IMAGE_MAX_LEBS = "225"
# FIRMWARE_IMAGE_MAX_LEBS was 214.  Removing the language pack freed up 38 LEB's.  The
# absolutely smallest ubifs we can create is 17 LEBs.  We might want to create a 17
# LEB file system to hold the persistent data (Wi-Fi calibration and such) and
# resize /data to something smaller than 64 MB (529 LEBs), but that requires further
# study.  For now, let's assume/require that the language pack has been removed from
# Create3 and that we can get an addition 22 LEBs (11 each, for the A & B images).
inherit swupdate

python do_swuimage_prepend () {
    import math
    def getsize(path):
        return os.popen('stat --printf="%s" $(readlink -f ' + path + ')').read()

    def size2lebs(size):
        return int(math.ceil(int(size) / 1024.0 / 124.0))

    base_image_size = getsize(d.getVar('DEPLOY_DIR_IMAGE', True) + '/base-image-' + d.getVar('MACHINE', True) + '.squashfs-xz')
    fit_image_size = getsize(d.getVar('DEPLOY_DIR_IMAGE', True) + '/fitImage')
    max_lebs = int(d.getVar('FIRMWARE_IMAGE_MAX_LEBS', True))
    if size2lebs(base_image_size) + size2lebs(fit_image_size) > max_lebs:
        bb.fatal("The image size exceeds the maximum size for the flash:\nbase_image_size = %d LEBs\nfit_image_size  = %d LEBs\nThe sum of these two values must be less than %d LEBs" % (size2lebs(base_image_size), size2lebs(fit_image_size), max_lebs))
	
    d.setVar('BASE_IMAGE_SIZE', base_image_size)
    d.setVar('FIT_IMAGE_SIZE', fit_image_size)
}
