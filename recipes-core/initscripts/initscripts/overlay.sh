#!/bin/sh

ROOT_FILESYSTEM=/dev/ubiblock0_rootfs
PROVISION_FILE=/data/overlay/upper/opt/irobot/config/provisioning
OVERLAY_DIR=/data/overlay

# for compatibility with the current persistent directory structure on robot,
# use default upper overly path
DATA_OVERLAY_ROOT=$OVERLAY_DIR/root
DATA_OVERLAY_WORK=$OVERLAY_DIR/work

# var is mounted as tmpfs so ignore it
BLACKLIST_DIRECTORIES="var"

# some of the var's sub-directories are mounted on root
# NOTE: excluded leading "/" to avoid double slash in mount path
OTHER_ROOT_DIRECTORIES="var/backups var/cache var/lib var/local var/spool"

# Return a list of the directories in / that are mounted on ROOT_FILESYSTEM
get_root_directories()
{
    all_root_entries=$(cd /; echo *)
    all_root_dirs=$OTHER_ROOT_DIRECTORIES
    for f in $all_root_entries; do
	# skip entries that a symbolic links or not directories
	if [ -h /$f -o ! -d /$f ] ; then continue; fi
	# skip blacklisted directories
	if echo $BLACKLIST_DIRECTORIES | grep -q $f; then continue; fi
	# skip directories that are not part of the root filesystem
	if ! $(df /$f | grep -q $ROOT_FILESYSTEM) ; then continue; fi
	all_root_dirs="$f $all_root_dirs"
    done
}

# Returns a list of overlay mount directories
get_overlay_directories()
{
    all_overlay_mount_dir=$(mount -t overlay | awk '{printf $3 " "}')
}

setup_devmode()
{
    get_root_directories

    for f in $all_root_dirs; do
	    mkdir -p $DATA_OVERLAY_ROOT/$f
	    mkdir -p $DATA_OVERLAY_WORK/$f
    done

    # Tell opkg to check /data for free space instead of / when installing packages
    mkdir -p $OVERLAY_DIR/root/etc/opkg
    cp /etc/opkg/opkg.conf $DATA_OVERLAY_ROOT/etc/opkg/opkg.conf
    echo "option overlay_root /data" >> $DATA_OVERLAY_ROOT/etc/opkg/opkg.conf
    exit 0
}

remove_overlay_dirs()
{
    rm -rf $DATA_OVERLAY_ROOT
    rm -rf $DATA_OVERLAY_WORK
    sync
}

teardown_devmode()
{
    get_overlay_directories

    for f in $all_overlay_mount_dir; do
        umount $f 2> /dev/null
    done

    # remove overlay directories
    remove_overlay_dirs
    exit 0
}

check_and_enable()
{
    DEV_MODE="disabled"
    # pull in the provisioning variables into this environment.
    # this may override DEV_MODE
    if [ -r ${PROVISION_FILE} ]; then
	    . ${PROVISION_FILE}
    fi

    if [ "$DEV_MODE" != "enabled"  ]; then
	    # Ensure that we clean up anything that might be leftover in OVERLAY_DIR
		remove_overlay_dirs
	    exit 0
    fi

    # setup required directories for overlay mount
    get_root_directories

    for f in $all_root_dirs; do
	    mkdir -p $DATA_OVERLAY_ROOT/$f
	    mkdir -p $DATA_OVERLAY_WORK/$f
    done

    # mount the overlay filesystems
    for f in $all_root_dirs; do
        mount -t overlay overlay -o lowerdir=/$f,upperdir=$DATA_OVERLAY_ROOT/$f,workdir=$DATA_OVERLAY_WORK/$f /$f || exit 1
    done

    exit 0
}

COMMAND=$1

case "$COMMAND" in
setup)
    setup_devmode
    ;;
teardown)
    teardown_devmode
    ;;
check-and-enable)
    check_and_enable
    ;;
*)
    echo "Usage: $0 {setup|teardown|check-and-enable}"
    exit 1
esac
