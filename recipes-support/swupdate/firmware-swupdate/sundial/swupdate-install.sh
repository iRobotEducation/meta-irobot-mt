#!/bin/sh
#
# This script will be called by swupdate.
#
INSTALL_LOG=/tmp/fwlog.txt
MACHINE=sundial
PROVISION_FILE=/opt/irobot/config/provisioning
if [ -r ${PROVISION_FILE} ] ; then
    . ${PROVISION_FILE}
fi

# add sbin to the PATH
export PATH=$PATH:/usr/sbin:/sbin


# grab harwdware revision #
HWREV=$(cat /etc/hwrevision | cut -d' ' -f2)

if [ $1 == "preinst" ]; then
	# parse script input, the last opt is user data which in
	# our case contains version to be installed
	# Save this into TARGET_VER_FILE for connectivity to
	# read once install is complete. 
	# TODO: remove this once connectivity code correctly
	# parses version from .swu file and stores it
	while [ $# -gt 1 ] 
	do 
		shift
	done

	PENDING_VERSION="$1"
	UPDATE_TYPE="0"
	TARGET_VER_FILE=/opt/irobot/persistent/opt/irobot/target_product_version_string
	UPDATE_TYPE_FILE=/opt/irobot/persistent/opt/irobot/target_update_type
	echo "Will install $PENDING_VERSION"
	echo $PENDING_VERSION > $TARGET_VER_FILE
	echo $UPDATE_TYPE > $UPDATE_TYPE_FILE
	sync

	# clear memory caches
	sync; echo 1 > /proc/sys/vm/drop_caches > /dev/null 2>&1
	sync; echo 2 > /proc/sys/vm/drop_caches  > /dev/null 2>&1
	sync; echo 3 > /proc/sys/vm/drop_caches  > /dev/null 2>&1

	cd /tmp/
	echo "Starting firmware install script"

	if [ -f /opt/irobot/version.env ] ; then
		. /opt/irobot/version.env
		echo "CURRENT PRODUCT VERSION:       $PRODUCT_VERSION" | sed s/+/\-/ | tee -a $INSTALL_LOG
		echo "CURRENT OS VERSION:            $OS_VERSION" | sed s/+/\-/ | tee -a $INSTALL_LOG
	else
		if [ -f /opt/irobot/version ] ; then
			echo "CURRENT OS VERSION: `cat /opt/irobot/version`" | sed s/+/\-/ | tee -a $INSTALL_LOG
		fi
	fi

	echo "--------------------------   df  ------------------------" | tee -a $INSTALL_LOG
	df >> $INSTALL_LOG
	echo "------------------------  meminfo  ----------------------" | tee -a $INSTALL_LOG
	cat /proc/meminfo >> $INSTALL_LOG
	echo "------------------------     mtd   ----------------------" | tee -a $INSTALL_LOG
	cat /proc/mtd >> $INSTALL_LOG
	echo "------------------------  cmdline   ---------------------" | tee -a $INSTALL_LOG
	cat /proc/cmdline >> $INSTALL_LOG
	echo "------------------------   uname    ---------------------" | tee -a $INSTALL_LOG
	uname -a >> $INSTALL_LOG
	echo "-----------------------   version   ---------------------" | tee -a $INSTALL_LOG
	if [ -f /usr/bin/version ] ; then
		version >> $INSTALL_LOG
	fi
	echo "-----------------------    uptime   ---------------------" | tee -a $INSTALL_LOG
	uptime >> $INSTALL_LOG
	echo "-----------------------      ps     ---------------------" | tee -a $INSTALL_LOG
	ps >> $INSTALL_LOG
	if [ -f /usr/bin/provision ] ; then
		echo "-----------------------  provision  ---------------------" | tee -a $INSTALL_LOG
		provision >> $INSTALL_LOG
	fi

	echo "Removing ubi volumes" | tee -a $INSTALL_LOG
	ubirmvol /dev/ubi0 -N new_kernel  > /dev/null 2>&1
	ubirmvol /dev/ubi0 -N new_rootfs  > /dev/null 2>&1
	ubirmvol /dev/ubi0 -N old_kernel  > /dev/null 2>&1
	ubirmvol /dev/ubi0 -N old_rootfs  > /dev/null 2>&1
	sync

	if [ $PRODUCT = "create3" ]; then
	    if ubinfo /dev/ubi0 -N language >/dev/null 2>&1; then
		echo "Removing language pack on Create3" | tee -a $INSTALL_LOG
		umount /opt/irobot/audio/languages 2>&1 | tee -a $INSTALL_LOG
		ubirmvol /dev/ubi0 -N language 2>&1 | tee -a $INSTALL_LOG
	    fi
	fi
fi

if [ $1 == "postinst" ]; then

    if [ "$HWREV" = "1.0" ]; then
        echo "UPDATING HWREV: ${HWREV}"

        cd /tmp/

        echo "Create new ubi volumes" | tee -a $INSTALL_LOG
        # complex invocation needed to preserve exit status of ubimkvol.
        ((((ubimkvol /dev/ubi0 -N new_rootfs -t static -s `ls -l base-image-${MACHINE}.squashfs-xz | awk '{print $5}'`; echo $? >&3) | tee -a $INSTALL_LOG >&4) 3>& 1) | (read xs; exit $xs)) 4>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Create new rootfs ubi volume failed" | tee -a $INSTALL_LOG
            echo "Firmware update has ended unsucessfully " | tee -a $INSTALL_LOG
            exit 1
        fi
        sync
        # complex invocation needed to preserve exit status of ubimkvol.
        ((((ubimkvol /dev/ubi0 -N new_kernel -t static -s `ls -l fitImage | awk '{print $5}'`; echo $? >&3) | tee -a $INSTALL_LOG >&4) 3>& 1) | (read xs; exit $xs)) 4>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Create new kernel ubi volume failed" | tee -a $INSTALL_LOG
            echo "Firmware update has ended unsucessfully " | tee -a $INSTALL_LOG
            exit 1
        fi
        sync
        echo "Update ubi volumes" | tee -a $INSTALL_LOG

        # it can take an indeterminate amount of time for the ubi device
        # file for new_rootfs to show up in /dev/ubi0_x.  use a loop to check for the
        # existance of the device file.
        RETRY_LIMIT=5
        c=1
        NEW_ROOTFS_DEV="/dev/`grep new_rootfs /sys/class/ubi/ubi0_*/name | awk -F/ '{print $5}'`"
        ls $NEW_ROOTFS_DEV > /dev/null 2>&1
        rc=$?
        while [ $rc -ne 0 -a $c -le $RETRY_LIMIT ]; do
            # new rootfs device not yet available
            sleep 1
            ls $NEW_ROOTFS_DEV > /dev/null 2>&1
            rc=$?
            c=`expr $c + 1`
        done

        if [ $rc -ne 0 ]; then
            # /dev/ubi0_x was not found. bummer
            echo "ERROR: ubi device file not found" | tee -a $INSTALL_LOG
            echo "Firmware update has ended unsucessfully " | tee -a $INSTALL_LOG
            exit 2
        fi
        # update the new rootfs
        ((((ubiupdatevol /dev/`grep new_rootfs /sys/class/ubi/ubi0_*/name | awk -F/ '{print $5}'`  base-image-${MACHINE}.squashfs-xz; echo $? >&3) | tee -a $INSTALL_LOG >&4) 3>& 1) | (read xs; exit $xs)) 4>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Update ubi rootfs volume failed" | tee -a $INSTALL_LOG
            echo "Firmware update has ended unsucessfully " | tee -a $INSTALL_LOG
            exit 2
        fi
        sync
        # update the new kernel
        ((((ubiupdatevol /dev/`grep new_kernel /sys/class/ubi/ubi0_*/name | awk -F/ '{print $5}'`  fitImage; echo $? >&3) | tee -a $INSTALL_LOG >&4) 3>& 1) | (read xs; exit $xs)) 4>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Update ubi kernel volume failed" | tee -a $INSTALL_LOG
            echo "Firmware update has ended unsucessfully " | tee -a $INSTALL_LOG
            exit 2
        fi
        sync
        echo "Installing the new volumes" | tee -a $INSTALL_LOG
        ((((ubirename /dev/ubi0 new_rootfs rootfs new_kernel kernel rootfs old_rootfs kernel old_kernel; echo $? >&3) | tee -a $INSTALL_LOG >&4) 3>& 1) | (read xs; exit $xs)) 4>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Update install new volumes has failed" | tee -a $INSTALL_LOG
            echo "Firmware update has ended unsucessfully " | tee -a $INSTALL_LOG
            exit 3
        fi

        sync

    fi

    if [ "$HWREV" = "1.1" ]; then
        echo "UPDATING HWREV: ${HWREV}"
        ((((ubirename /dev/ubi0 new_rootfs rootfs new_kernel kernel rootfs old_rootfs kernel old_kernel; echo $? >&3) | tee -a $INSTALL_LOG >&4) 3>& 1) | (read xs; exit $xs)) 4>&1
        if [ $? -ne 0 ]; then
            echo "ERROR: Update install new volumes has failed" | tee -a $INSTALL_LOG
            echo "Firmware update has ended unsucessfully " | tee -a $INSTALL_LOG
            exit 3
        fi
        sync
    fi

fi

exit 0
