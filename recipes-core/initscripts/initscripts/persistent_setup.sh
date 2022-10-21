#/bin/sh
# setup persistent files

DEV_MODE="disabled"
# pull in the provisioning variables into this environment.
# this may over ride DEV_MODE.
# use the persistent file location as /opt/irobot/config has not yet been mounted.
PROVISION_FILE=/data/overlay/upper/opt/irobot/config/provisioning
if [ -r ${PROVISION_FILE} ] ; then
    . ${PROVISION_FILE}
fi

make_persistent_dirs ()
{
  DATA_UPPER_DIR=/data/overlay/upper
  mkdir -p $DATA_UPPER_DIR/etc/network
  mkdir -p $DATA_UPPER_DIR/var/lib/urandom
  mkdir -p $DATA_UPPER_DIR/opt/irobot/persistent/opt/irobot/certs
  mkdir -p $DATA_UPPER_DIR/opt/irobot/persistent/opt/irobot/data/kvs
  mkdir -p $DATA_UPPER_DIR/opt/irobot/persistent/opt/irobot/data/mfg
  mkdir -p $DATA_UPPER_DIR/opt/irobot/persistent/maps
  mkdir -p $DATA_UPPER_DIR/opt/irobot/models
  mkdir -p $DATA_UPPER_DIR/opt/irobot/data
  mkdir -p $DATA_UPPER_DIR/opt/irobot/logs/firmware_install
  mkdir -p $DATA_UPPER_DIR/opt/irobot/config
}

setup_overlay_and_mount_copybind ()
{
  echo "Development mode status: $DEV_MODE"

  # overlays to enable development debug and opkg installs
  # DO THIS BEFORE mount-copybind'ing everything below so that the mount-copybind's are mounted
  # on the overlaid file systems (and not obscured by the overlaid file systems).
  if [ -f /usr/bin/overlay.sh ] ; then
    /usr/bin/overlay.sh check-and-enable
  fi
    #use mount-copybind for specific persistent files
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/hostapd.conf /etc/hostapd.conf
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/udhcpd.conf /etc/udhcpd.conf
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/wpa_supplicant.conf /etc/wpa_supplicant.conf
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/hostname /etc/hostname
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/hosts /etc/hosts
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/network/interfaces /etc/network/interfaces
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/timestamp /etc/timestamp
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/resolv.conf /etc/resolv.conf
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/ntp.conf /etc/ntp.conf
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/etc/wireless/mediatek/RT30xxEEPROM.bin /etc/wireless/mediatek/RT30xxEEPROM.bin
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/var/lib/urandom/ /var/lib/urandom > /dev/null 2>&1
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/opt/irobot/logs/ /opt/irobot/logs > /dev/null 2>&1
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/opt/irobot/config/ /opt/irobot/config  > /dev/null 2>&1
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/opt/irobot/models/ /opt/irobot/models  > /dev/null 2>&1
    /usr/sbin/mount-copybind $DATA_UPPER_DIR/opt/irobot/persistent/ /opt/irobot/persistent  > /dev/null 2>&1
}

set_access ()
{
  if [ ! -h /data/logs ]; then
    ln -sf /data/overlay/upper/opt/irobot/logs /data/logs
  fi
  chown -R root:apps /dev/ttyS0
  chmod -R ug+rw  /dev/ttyS0
  # if the link for /dev/ttyMobility0 does not exist, create it
  if [ ! -h /dev/ttyMobility0 ]; then
    ln -sf /dev/ttyS0 /dev/ttyMobility0
  fi
  chown -R root:apps /opt/irobot/persistent
  chmod -R ug+rw  /data/overlay/upper/opt/irobot/persistent
  chown -R root:apps /etc/ntp.conf
  chmod -R ug+rw  /etc/ntp.conf
  chown -R root:apps /etc/wpa_supplicant.conf
  chmod -R ug+rw  /etc/wpa_supplicant.conf
  # set the user and group executable bit for all directories under
  # /opt/irobot/persistent. this is a work around for cleantrack to
  # allow cleantrack to remove directories it has created.
  find /data/overlay/upper/opt/irobot/persistent -type d -print0 | xargs chmod ug+x
  chown -R root:apps /data/overlay/upper/opt/irobot/logs
  chmod -R ug+rw  /data/overlay/upper/opt/irobot/logs
  chown -R apps /sys/class/gpio
  chmod -R ug+rw /sys/class/gpio
  sync
}

fix_udhcpd ()
{
  grep -s -q interface /etc/udhcpd.conf
  if [ $? -ne 0 ] ; then
    cp /etc/udhcpd.conf.default /etc/udhcpd.conf
    sync
  fi
}

fix_wpa_supplicant ()
{
  grep -s -q interface /etc/wpa_supplicant.conf
  if [ $? -ne 0 ] ; then
    cp /etc/wpa_supplicant.conf.default /etc/wpa_supplicant.conf
    sync
  fi
}

mount_lang_pack ()
{
  # attempt to mount a language pack and extra languages volumes
  if [ -d /opt/irobot/audio/languages ];  then
    # look for a language volume
    DEV_NUM=$(ubinfo  /dev/ubi0 -N language 2> /dev/null | awk '/Volume ID/ {print $3}')
    # validate that DEV_NUM is an integer
    [ -n "$DEV_NUM" ] && [ "$DEV_NUM" -eq "$DEV_NUM" ] 2>/dev/null
    if [ $? -eq 0 ]; then
      ubiblock -c /dev/ubi0_${DEV_NUM}
      # check for /dev/ubiblock0_language, may take some time to appear
      COUNT=0
      while ! [ -b /dev/ubiblock0_language ]
      do
        sleep 0.5
        COUNT=$(($COUNT+1))
        if [ $COUNT -gt 6 ]; then
          # timed out
          break
        fi
      done
    fi
    if [ -b  /dev/ubiblock0_language ]; then
      mount -r /dev/ubiblock0_language /opt/irobot/audio/languages
    fi

    # look for an extra lang volume
    DEV_NUM=$(ubinfo  /dev/ubi0 -N extra_lang 2> /dev/null | awk '/Volume ID/ {print $3}')
    # validate that DEV_NUM is an integer
    [ -n "$DEV_NUM" ] && [ "$DEV_NUM" -eq "$DEV_NUM" ] 2>/dev/null
    if [ $? -eq 0 ]; then
      ubiblock -c /dev/ubi0_${DEV_NUM}
      # check for /dev/ubiblock0_extra_lang, may take some time to appear
      COUNT=0
      while ! [ -b /dev/ubiblock0_extra_lang ]
      do
        sleep 0.5
        COUNT=$(($COUNT+1))
        if [ $COUNT -gt 6 ]; then
          # timed out
          break
        fi
      done
    fi
    if [ -b  /dev/ubiblock0_extra_lang ]; then
      mount -r /dev/ubiblock0_extra_lang /opt/irobot/audio/languages/${EXTRA_LANGUAGE}
    fi
  fi
}

make_crypto_block ()
{
  # attempt to create crypto block from a volume.
  # look for a crypto volume
  DEV_NUM=$(ubinfo  /dev/ubi0 -N crypto 2> /dev/null | awk '/Volume ID/ {print $3}')
  # validate that DEV_NUM is an integer
  [ -n "$DEV_NUM" ] && [ "$DEV_NUM" -eq "$DEV_NUM" ] 2>/dev/null
  if [ $? -eq 0 ]; then
    ubiblock -c /dev/ubi0_${DEV_NUM}
    # check for /dev/ubiblock0_crypto, may take some time to appear
    COUNT=0
    while ! [ -b /dev/ubiblock0_crypto ]
    do
      sleep 0.5
      COUNT=$(($COUNT+1))
      if [ $COUNT -gt 6 ]; then
        # timed out
        break
      fi
    done
  fi
}

remove_core_files ()
{
  # remove core dump files if size of "/data/logs" directory exceeds 20M (As size of partition is 57.5M)
  LOG_DIR_SIZE=$(du -ms /data/logs/ | awk '{print $1}')
  if [ $LOG_DIR_SIZE -gt 20 ]; then
    rm /data/logs/core*
  fi
}

remove_tmp_files ()
{
  # search and remove any lefover tmp.xxxxxx files in /data/logs/ created with
  # mktemp while core file generation (see coredump-proxy.sh). This temp file
  # will have exact six chars after "tmp." e.g. /data/logs/tmp.nAfGbE
  # remove only those files and keep the rest files starting with tmp.*
  find /data/logs/ -name 'tmp.??????' | xargs -r rm -rf
}

# create persistent directories
make_persistent_dirs

# overlay mount all desired directories or copybind specific files
setup_overlay_and_mount_copybind

# check critical config files
fix_udhcpd
fix_wpa_supplicant
# set file and directory access
set_access
mount_lang_pack
make_crypto_block
remove_core_files
remove_tmp_files
sync

exit 0
