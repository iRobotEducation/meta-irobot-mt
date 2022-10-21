#!/bin/sh

# run swupdate

# Specify acceptable PATH
PATH=/usr/bin:/bin:/usr/sbin:/sbin

# error/return/exit codes

# are in sync with /usr/include/sysexits.h
EX_OK=0
EX_USAGE=64
EX_DATAERR=65
EX_NOINPUT=66
EX_NOUSER=67
EX_NOHOST=68
EX_UNAVAILABLE=69
EX_SOFTWARE=70
EX_OSERR=71
EX_OSFILE=72
EX_CANTCREAT=73
EX_IOERR=74
EX_TEMPFAIL=75
EX_PROTOCOL=76
EX_NOPERM=77
EX_CONFIG=78
EX__MAX=78
EX_GENERAL=1
LOG_LOC="/opt/irobot/logs/firmware_install"
PROVISION_FILE=/opt/irobot/config/provisioning
FILE="OTA_UPDATE"
INSTALL_LOG="${LOG_LOC}/${FILE}.log"
mkdir -p $LOG_LOC

# Nor flash mtd devices that doesn't require to attach while performing OTA
# By default swupdate will try to to attach all mtd partition as ubi volume.
#
# mtd0:         uboot
# mtd1:         reserved
# mtd2:         factory_unlock
# mtd3:         backup
# mtd4:         crypto
MTD_BLACKLIST="0 1 2 3 4"

if [[ $(id -u $(whoami)) != 0 ]]; then
    echo "Error: $0 should be run with root privileges"
    exit $EX_USAGE;
fi

# usage
usage() {
   RET_CODE=$1;
   echo "usage: $0 [-h] [-d] [-f|-F] <ota file>"
   echo " -f <ota file>  - install ota file provided robot type checks pass"
   echo " -F <ota file>  - install ota file even if robot type checks fail"
   echo " -d             - perform checks but do not perform actual update"
   echo " -n             - don't reboot the system at the end of the update. This flag can be used with language-pack installation only"
   echo " -r             - don't stop cleantrack before installing update"
   echo " -c             - get version and other info from image. Use with -f <ota file>"
   echo " -h             - help"
   exit $RET_CODE
}

trim() {
    var="$1"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
}

# save the number of arguments passed to the script
ARGS=$#
OTA_FILE=""
DEBUG_FLAG=""
REBOOT_FLAG=""
STOP_CLEANTRACK_FLAG=""
DO_CHECK=""

# save the last 3 log files (filename extensions are -0, -1 and -2):
# rotate the current set of log files (ie 0->1, 1->2)
for i in 1 0; do
  if [ -f ${INSTALL_LOG}-$i ]; then
    mv ${INSTALL_LOG}-$i ${INSTALL_LOG}-$((i+1));
  fi
done

# move the last log file to 0
if [ -f ${INSTALL_LOG} ]; then
  mv ${INSTALL_LOG} ${INSTALL_LOG}-0
fi
# create the new log file
echo Script $0 called with parameters "$@" > ${INSTALL_LOG}

while [ "$1" ]; do
   case "$1" in
      -f) OTA_FILE=$2; FORCE=no; shift;;
      -F) OTA_FILE=$2; FORCE=yes; shift;;
      -d) DEBUG_FLAG="debug";;
	  -n) REBOOT_FLAG="false";;
      -r) STOP_CLEANTRACK_FLAG="false";;
      -c) DO_CHECK="true";;
      -h) usage $EX_USAGE;;
      *) echo Invalid parameter: $1 | tee -a $INSTALL_LOG ; usage $EX_USAGE;;
   esac
   shift
done

# == CHECK OTA FILE SPECIFIED ==
if [ -z $OTA_FILE ] ; then
  echo "Error: OTA file was not specified" | tee -a $INSTALL_LOG
  usage $EX_USAGE
fi

# == CHECK OTA FILE PRESENT ==
if [ ! -f $OTA_FILE ]; then
  echo "Error: could not find OTA file $OTA_FILE" | tee -a $INSTALL_LOG
  exit $EX_NOINPUT
fi

# == CHECK FILESIZE NON-ZERO ==
if [ ! -s $OTA_FILE ]; then
  echo "Error: OTA filesize zero $OTA_FILE" | tee -a $INSTALL_LOG
  exit $EX_DATAERR
fi

# == CHECK DIRECTORY PERMISSIONS ==
if [ ! -w `pwd` ] ; then
  echo "Error: You must run $0 from a writeable directory" | tee -a $INSTALL_LOG
  exit $EX_NOPERM
fi

if [ ! -z $DEBUG_FLAG ] ; then
  exit 1
else
  if [ -z $STOP_CLEANTRACK_FLAG ] && [ -z $DO_CHECK ] ; then 
    # Stop the cleantrack app and continue with the installation process.
    # Do not change the cleantrack stop process from here until communication
    # between cleantrack and connectivity is re-architected properly to stop
    # cleantrack in OTA installation process
    /etc/init.d/cleantrack.init stop > /dev/null 2>&1
  fi
fi

# == EXTRACT THE RSA PUBLIC KEYS FROM THE MTAL ==
mkdir -p /tmp/mtal-keys
mtal-extractor /dev/ubi0_$(ubinfo /dev/ubi0 -N crypto | awk '/Volume ID/ {print $3}') /tmp/mtal-keys | tee -a $INSTALL_LOG
mtal-extractor /dev/ubi0_$(ubinfo /dev/ubi0 -N prev_crypto | awk '/Volume ID/ {print $3}') /tmp/mtal-keys | tee -a $INSTALL_LOG

# == SHOULD WE ENFORCE SIGNATURE CHECKING ON UPGRADE? ==
# Let's start by saying: NO
DEVMODE_PARAMS="--signature-check-optional --hash-optional"

# if just doing a check, run swupdate with --query opt and don't 
# write to install log, also don't do signature checks
if [ ! -z $DO_CHECK ] ; then 
   for f in /tmp/mtal-keys/*; do
       KEYFILE=$f
       if swupdate -i $OTA_FILE -k $KEYFILE $DEVMODE_PARAMS --quiet --query=version,description,iRobot-userdata; then 
          rm -rf /tmp/mtal-keys
          exit 0
       fi
   done
   rm -rf /tmp/mtal-keys  
   exit 1
fi

# If we're running production code, then YES
if version | grep -q PRODUCTION; then
    DEVMODE_PARAMS=""
fi
# If the code was signed, then YES
if cpio -it --quiet -F $OTA_FILE | grep -q sw-description.sig; then
    DEVMODE_PARAMS=""
fi

# Try each key file in succession.  It would be better to make
# swupdate smarter and to take a directory of keys instead of a single
# key file.
rm -f /tmp/swupdate_complete
for f in /tmp/mtal-keys/*; do
    KEYFILE=$f
    (if swupdate -i $OTA_FILE -k $KEYFILE $DEVMODE_PARAMS -b "$MTD_BLACKLIST" 2>/tmp/stderr.log; then
	cat /tmp/stderr.log | tee -a $INSTALL_LOG
	echo "Found signing key: $KEYFILE, DEVMODE_PARAMS=\"$DEVMODE_PARAMS\"" | tee -a $INSTALL_LOG
	touch /tmp/swupdate_complete
    fi) | tee -a $INSTALL_LOG
    if [ -e /tmp/swupdate_complete ]; then
	break
    fi
done

rm -f $OTA_FILE
sync

if [ ! -z $REBOOT_FLAG ] ; then
#== CHECK IF REBOOT_FLAG USED FOR FIRMWARE INSTALLATION ==
#if REBOOT_FLAG is used with other than language-pack, inform user to reboot, otherwise next ota flash may fail.
  echo "$OTA_FILE" | grep -q "language-pack"
  if [ $? -eq 1 ] ; then
   echo "Firmware flashed, please reboot the robot to boot with new firmware. Subsequent ota firmware flashing may fail, if robot is not rebooted now"
  fi
  if [ -z $STOP_CLEANTRACK_FLAG ] ; then
    /etc/init.d/cleantrack.init start > /dev/null 2>&1
  fi
  if [ ! -e /tmp/swupdate_complete ]; then
    echo "Error installing $OTA_FILE"
    exit 1
  else
    exit 0
  fi
fi

if [ -e /tmp/swupdate_complete ] ; then

  # disable development mode
  provision --devmode disabled

  echo "Reboot..."
  reboot
  exit 0
else
  echo "Error installing $OTA_FILE"
  exit 1
fi
