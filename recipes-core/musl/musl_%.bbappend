FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

# FIXME:
#   Currently adding a patch to iRobot builds.
# TODO:
#   Raise a bug with official musl community and provide the suggested
#   patch to fix with more information on scenario, design of inter process
#   communication for synchronization and references from other standard c
#   libraries for the same
# NOTE:
#   glibc unmaps shared semaphore memory only when refcount becomes zero
#   glibc references:
#       upstream commit :   68a396e83a8e1e50d0dfde8ffb090a8df311453f
#       glibc release   :   glibc-2.3.3 (tag)
#   in patch 0002-sem-unmap-semaphore-resources-when-refcount-is-zero-.patch
#   goto statement can be used for failure cases to UNLOCK and return -1
#   instead of having same code twice. In this case it is not worth to use
#   goto statement in short code and in only two places as failure related
#   statements already in branch prediction (though based on compiler) and
#   might add load for fetcher pipeline.
#   if anyone feels it is better to use goto instead of failure code block
#   twice, then feel free to add/change the same.
#   in 0002-sem-unmap-semaphore-resources-when-refcount-is-zero-.patch call to
#   munmap is prefixed with '-' to have positive value in errno instead of
#   negative and this is insync with existing coding/calling procedure in musl
#   c library. And single line of code in if statement when the conditional
#   code block is not more than one line which is also again insync with musl
#   c library existing coding procedure/style.
SRC_URI += "\
    file://0001-sem-set-appropriate-errno-and-return-value-in-sem_cl.patch \
    file://0002-sem-unmap-semaphore-resources-when-refcount-is-zero-.patch \
    file://0003-fix-namespace-violation-in-dependencies-of-mtx_lock.patch \
    file://0004-clean-up-access-to-mutex-type-in-pthread-mutex-trylo.patch \
    file://0005-implement-priority-inheritance-mutexes.patch \
    file://0006-Add-some-CFI-directives-to-MIPS-asm-sources.patch \
    file://0007-Teach-dynlink.c-about-DT_MIPS_RLD_MAP_REL.patch \
    file://0008-fix-static-tls-offsets-of-shared-libs-on-TLS_ABOVE_T.patch \
    "

do_install_append() {
	install -d ${D}${base_libdir}
        # sdk needs libc.so in the base_libdir
        lnr  ${D}${base_libdir}/ld.so.1 ${D}${libdir}/libc.so.1
}

FILES_${PN} += "${base_libdir}/* "
