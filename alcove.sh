#!/system/bin/sh

# MIT License
#
# Copyright (c) 2018-2019 urain39 & Kyono
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# NOTE: Below exit codes also applied to sub-scripts,
#       such as ${NEWROOT}/init.sh ...

NO_ERROR=0
ENV_ERROR=1
PERM_ERROR=2
BOOT_ERROR=3
UNKNOW_ERROR=255

# XXX: `id -u` may not work on android.
if [ x"${UID}" = "x" ]; then
  UID=`id`
  UID=${UID#*=}
  UID=${UID%% *}
  UID=${UID%\(*}
fi

BOOT_DIR=""
umask 022 # Fix default permission.

#
# Prechecks
#

type chroot > /dev/null 2>&1 || {
  echo "Not found chroot!"
  echo "Please install chroot and try again!"
  exit ${ENV_ERROR}
}

[ "${UID}" != "0" ] && {
  echo "Please run ${0##*/} as root!"
  exit ${PERM_ERROR}
}

#
# Functions
#

show_help()
{
  cat <<HELP
alcove - a script to run linux on termux.

Usage: ${0##*/} <init|boot> <bootdir>

See also:
  QQGroup: 494453985
  https://github.com/95e2/linux-on-termux
HELP
}

check_env()
{
  if [ x${BOOT_DIR} = "x" ] || [ ! -d ${BOOT_DIR} ]; then
    echo "Not found path [${BOOT_DIR}]!"
    exit ${ENV_ERROR}
  fi
  [ "${BOOT_DIR}" = "/" ] && exit ${ENV_ERROR}
}

alcove_init()
{
  cat > ${BOOT_DIR}/init.sh <<INIT_SCRIPT
#!/bin/sh

unset PREFIX TMPDIR HOME SHELL
unset LD_LIBRARY_PATH HISTFILE
unset ANDROID_ROOT ANDROID_DATA
unset EXTERNAL_STORAGE PROOT_TMP_DIR

export TERM="xterm"
export HOME="/root"
export PATH="/bin:/sbin:/usr/bin:/usr/sbin"
export PATH="\${PATH}:/usr/local/bin:/opt/bin"

# Preload profile
. /etc/profile

# Show logo, even though it was crashed.
echo "    _    _                    "
echo "   / \\\\  | | ___ _____   _____ "
echo "  / _ \\\\ | |/ __/ _ \\\\ \\\\ / / _ \\\\"
echo " / ___ \\\\| | (_| (_) \\\\ V /  __/"
echo "/_/   \\\\_\\\\_|\\\\___\\\\___/ \\\\_/ \\\\___| v1.2.5"
echo "                              "
echo " A chroot scripts to run linux on termux."

if [ -f /tmp/.alcove/alcove.running ]; then
  echo "Do not run /init.sh on a same system twice or more!"
  # NOTE: Exit code has been formatted.
  exit ${UNKNOW_ERROR}
fi

echo "IS RUNNING" > /tmp/.alcove/alcove.running

#
# Event-Hooks
#

COLOR_RESET="\033[0m"
COLOR_CLEAR="\r\033[K"
COLOR_BOLD_RED="\033[1;31m"
COLOR_BOLD_GREEN="\033[1;32m"

clear_print() {
  printf "\${COLOR_CLEAR}\${@}"
}

print_msg() {
  printf "\${@}"
}

print_ok() {
  clear_print "[  \${COLOR_BOLD_GREEN}OK\${COLOR_RESET}  ] \${@}\n"
}

print_failed() {
  clear_print "[\${COLOR_BOLD_RED}FAILED\${COLOR_RESET}] \${@}\n"
}

if [ -d /alcove-hooks ]; then
  rm -rf /tmp/.alcove/alcove-hooks # Path-Safe
  cp -rp /alcove-hooks /tmp/.alcove/alcove-hooks

  print_msg "Starting...\n"
  for s in /tmp/.alcove/alcove-hooks/*; do
    if [ ! -f \${s} ] || [ ! -x \${s} ]; then
      continue
    fi

    print_msg "Starting \${s} ..."
    \${s} "start"

    if [ \${?} = 0 ]; then
      print_ok "\${s}"
    else
      print_failed "\${s}"
    fi
  done

  su - root; ret=\${?}

  print_msg "Stopping...\n"
  ls /tmp/.alcove/alcove-hooks/* | sort -r | while read s; do
    if [ ! -f \${s} ] || [ ! -x \${s} ]; then
      continue
    fi

    print_msg "Stopping \${s} ..."
    \${s} "stop"

    if [ \${?} = 0 ]; then
      print_ok "\${s}"
    else
      print_failed "\${s}"
    fi
  done
else
  su - root; ret=\${?}
fi

# Cleanup
rm /tmp/.alcove/alcove.running
exit \${ret}
INIT_SCRIPT

  chmod 755 ${BOOT_DIR}
  chmod 750 ${BOOT_DIR}/init.sh

  # alcove binds
  cat > ${BOOT_DIR}/alcove.binds <<ALCOVE_BINDS
# Syntax:
#   source_dir  newroot_dir
#   Use '#' at begin of a line to comment it.

# Example:

# sdcard
/sdcard  /mnt/intsd
ALCOVE_BINDS

  chmod 644 ${BOOT_DIR}/alcove.binds

  # mount point
  mkdir -p ${BOOT_DIR}/mnt/intsd
  mkdir -p ${BOOT_DIR}/mnt/extsd

  chmod 755 ${BOOT_DIR}/mnt/intsd
  chmod 755 ${BOOT_DIR}/mnt/extsd

  # alcove hooks
  mkdir -p ${BOOT_DIR}/alcove-hooks
  cat > ${BOOT_DIR}/alcove-hooks/00-alcover <<00_ALCOVER
#! /bin/sh

# Filename: /alcove-hooks/00-alcover

NAME="alcover"

start() { :; }

stop() { :; }

case "\${1}" in
  start)
    start
    ;;
  stop)
    stop
    ;;
esac
00_ALCOVER

  chmod 755 ${BOOT_DIR}/alcove-hooks
  chmod 755 ${BOOT_DIR}/alcove-hooks/00-alcover
}

alcove_mount()
{
  if [ -f ${BOOT_DIR}/tmp/.alcove/alcove.mounted ]; then
    return
  fi

  mount -o bind /dev ${BOOT_DIR}/dev
  mount -o bind /dev/pts ${BOOT_DIR}/dev/pts
  mount -o bind /proc ${BOOT_DIR}/proc
  mount -o bind /sys ${BOOT_DIR}/sys
  mount -t tmpfs tmpfs ${BOOT_DIR}/tmp

  if [ ! -d ${BOOT_DIR}/tmp/.alcove ]; then
    mkdir ${BOOT_DIR}/tmp/.alcove
  fi

  if [ ! -d ${BOOT_DIR}/dev/shm ]; then
    mkdir ${BOOT_DIR}/dev/shm && mount -t tmpfs tmpfs ${BOOT_DIR}/dev/shm \
                              && chmod 1777 ${BOOT_DIR}/dev/shm
    echo "SHM LOCKED" > ${BOOT_DIR}/tmp/.alcove/alcove.shmlock
  fi

  if [ -f ${BOOT_DIR}/alcove.binds ]; then
    # Fix error when user edited /alcove.binds .
    sed -n '/^#/d;/^[ \t]*$/d;p' ${BOOT_DIR}/alcove.binds > ${BOOT_DIR}/tmp/.alcove/alcove.binds
    cat ${BOOT_DIR}/tmp/.alcove/alcove.binds | while read SRC_PNT DST_PNT; do
      mount -o bind ${SRC_PNT} ${BOOT_DIR}/${DST_PNT}
    done
  fi

  if [ -d /data ] && [ -d /sdcard ]; then
    mount -o suid,remount /data
  fi

  echo "IS MOUNTED" > ${BOOT_DIR}/tmp/.alcove/alcove.mounted
}

alcove_umount()
{
  if [ ! -f ${BOOT_DIR}/tmp/.alcove/alcove.mounted ]; then
    return
  fi

  if [ -f ${BOOT_DIR}/tmp/.alcove/alcove.shmlock ]; then
    umount ${BOOT_DIR}/dev/shm && rm -r ${BOOT_DIR}/dev/shm
    rm ${BOOT_DIR}/tmp/.alcove/alcove.shmlock
  fi

  umount ${BOOT_DIR}/dev/pts
  umount ${BOOT_DIR}/dev
  umount ${BOOT_DIR}/proc
  umount ${BOOT_DIR}/sys

  if [ -f ${BOOT_DIR}/tmp/.alcove/alcove.binds ]; then
    cat ${BOOT_DIR}/tmp/.alcove/alcove.binds | while read SRC_PNT DST_PNT; do
      umount ${BOOT_DIR}/${DST_PNT}
    done
  fi

  if [ -d /data ] && [ -d /sdcard ]; then
    mount -o nosuid,remount /data
  fi

  rm ${BOOT_DIR}/tmp/.alcove/alcove.mounted
  # Why and who cares about others?
  rm -r ${BOOT_DIR}/tmp/.alcove
  umount ${BOOT_DIR}/tmp
}

alcove_boot()
{
  unset LD_PRELOAD
  if [ ! -f ${BOOT_DIR}/etc/.resolv.conf.ok ]; then
    rm -f ${BOOT_DIR}/etc/resolv.conf
    echo "nameserver 8.8.4.4" > ${BOOT_DIR}/etc/resolv.conf
    echo "nameserver 8.8.8.8" >> ${BOOT_DIR}/etc/resolv.conf
    chmod 644 ${BOOT_DIR}/etc/resolv.conf
    echo "DNS IS OK" > ${BOOT_DIR}/etc/.resolv.conf.ok
  fi

  [ ! -f ${BOOT_DIR}/init.sh ] && {
    echo "Not found [${BOOT_DIR}/init.sh]"
    echo "Have you run ${0##*/} init?"
    exit ${BOOT_ERROR}
  }


  [ -f ${BOOT_DIR}/tmp/.alcove/alcove.mounted ] && {
    echo "Do not boot a same system twice or more!"
    exit ${BOOT_ERROR}
  }

  alcove_mount
  chroot ${BOOT_DIR} /init.sh
  alcove_umount
}

main()
{
  if [ ${#} -lt 2 ]; then
    show_help
    exit ${NO_ERROR}
  fi

  BOOT_DIR=`cd ${2}; pwd` > /dev/null 2>&1

  check_env
  case "${1}" in
  "init")
    alcove_init
    ;;
  "boot")
    alcove_boot
    ;;
  *)
    show_help
    exit ${NO_ERROR}
    ;;
  esac
}


main "${@}"
