DESCRIPTION = "Generate firmware-fitImage"
SECTION = ""

# This recipe computes the checksum of the rootfs, embeds it in the device tree
# used by the kernel, and packages the kernel, device-tree, and initramfs into
# the firmware-fitImage to be used by the firmware-swupdate recipe.
# All of the heavy lifting is done by the build_fitimage function defined in
# fitimage.bbclass
# We deploy the resulting firmware-fitImage to ${DEPLOYDIR} for consumption by
# firmware-swupdate.bb

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Proprietary;md5=0557f9d92cf58f2ccdd50f62f8ac0b28"

inherit fitimage

do_compile () {
    build_fitimage
}
# The build_fitimage function depends on the base-image, the initramfs, and the kernel.  Technically
# (and unnecessarily), the kernel depends on initramfs:do_image_complete as well (see kernel.bbclass and
# search for INITRAMFS_IMAGE), but, in case that ever changes, we explicitly call out the dependency here.
do_compile[depends] += "base-image:do_image_complete initramfs:do_image_complete virtual/kernel:do_deploy"

# ensure that do_compile always runs, even when the sstate cache thinks that it shouldn't because it believes
# that its inputs (base-image, initramfs, the kernel, the device tree) haven't changed.  We have run into
# issues where base-image:do_rootfs (and :do_deploy) have run, changing the timestamps in the rootfs, which
# leads to the checksum of the rootfs changing, but sstate does not run do_compile (and therefore does not
# update the checksum embedded in the device tree), leading to a boot failure.
#
# If you never run `bitbake base-image -ccleanall` this wouldn't be a problem.  If you do, then this ensures
# that you still produce a working image.
do_compile[nostamp] = "1"

inherit deploy
do_deploy() {
   cp ${B}/fitImage ${DEPLOYDIR}/fitImage
}

addtask deploy after do_install
