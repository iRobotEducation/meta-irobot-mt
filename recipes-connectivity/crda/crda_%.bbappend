FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

# remove dependency on udev.  this allows mdev to be the hotplug solution.
RDEPENDS_${PN}_remove = "udev"
