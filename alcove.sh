#!/system/bin/sh

NO_ERROR=0;
ENV_ERROR=1;
PERM_ERROR=2;
BOOT_ERROR=3;

UID=`id`;
UID=${UID#*=};
UID=${UID%% *};
BOOT_DIR="";

umask 022; # Fix default permission.


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

type chroot > /dev/null 2>&1 || {
  echo "Not found chroot!";
  echo "Please install chroot and try again!";
  exit $ENV_ERROR;
};

[ "$UID" != "0(root)" ] && {
  echo "Please run ${0##*/} as root!";
  exit $PERM_ERROR;
};

check_env()
{
  if [ x$BOOT_DIR = "x" ] || [ ! -d $BOOT_DIR ]; then
    echo "Not found path [$BOOT_DIR]!";
    exit $ENV_ERROR;
  fi;
  [ "$BOOT_DIR" = "/" ] && exit $ENV_ERROR;
}

alcove_init()
{
  cat > $BOOT_DIR/init.sh <<INIT_SCRIPT
#!/bin/sh

unset PREFIX TMPDIR HOME SHELL;
unset LD_LIBRARY_PATH HISTFILE;
unset ANDROID_ROOT ANDROID_DATA;
unset EXTERNAL_STORAGE PROOT_TMP_DIR;

export TERM="xterm";
export HOME="/root";
export PATH="/bin:/sbin:/usr/bin:/usr/sbin";
export PATH="\$PATH:/usr/local/bin:/opt/bin";

# Preload profile
. /etc/profile;

# Show logo, even though it was crashed.
echo "    _    _                    ";
echo "   / \\\\  | | ___ _____   _____ ";
echo "  / _ \\\\ | |/ __/ _ \\\\ \\\\ / / _ \\\\";
echo " / ___ \\\\| | (_| (_) \\\\ V /  __/";
echo "/_/   \\\\_\\\\_|\\\\___\\\\___/ \\\\_/ \\\\___| v1.2.4";
echo "                              ";
echo " A chroot scripts to run linux on termux.";

su - root; exit \$?;
INIT_SCRIPT

  chmod 755 $BOOT_DIR;
  chmod 750 $BOOT_DIR/init.sh;
}

alcove_mount()
{
  if [ -f $BOOT_DIR/tmp/.isMounted ]; then
    return;
  fi;

  mount -o bind /dev $BOOT_DIR/dev;
  mount -o bind /dev/pts $BOOT_DIR/dev/pts;
  mount -o bind /proc $BOOT_DIR/proc;
  mount -o bind /sys $BOOT_DIR/sys;
  mount -t tmpfs tmpfs $BOOT_DIR/tmp;

  if [ ! -d $BOOT_DIR/dev/shm ]; then
    mkdir $BOOT_DIR/dev/shm && mount -t tmpfs tmpfs $BOOT_DIR/dev/shm \
                            && chmod 1777 $BOOT_DIR/dev/shm;
  fi;

  if [ -f $BOOT_DIR/alcove.binds ]; then
    # Fix when user edited /alcove.binds .
    sed -n '/^#/d;p' $BOOT_DIR/alcove.binds > $BOOT_DIR/tmp/.alcove.binds;
    cat $BOOT_DIR/tmp/.alcove.binds | while read SRC_PNT MNT_PNT; do
      mount -o bind $SRC_PNT $BOOT_DIR/$MNT_PNT;
    done;
  fi;

  if [ -d /data ] && [ -d /sdcard ]; then
    mount -o suid,remount /data;
  fi;

  echo "IS MOUNTED" > $BOOT_DIR/tmp/.isMounted;
}

alcove_umount()
{
  if [ ! -f $BOOT_DIR/tmp/.isMounted ]; then
    return;
  fi;

  if [ -d $BOOT_DIR/dev/shm ]; then
    umount $BOOT_DIR/dev/shm && rm -r $BOOT_DIR/dev/shm;
  fi;

  umount $BOOT_DIR/dev/pts;
  umount $BOOT_DIR/dev;
  umount $BOOT_DIR/proc;
  umount $BOOT_DIR/sys;

  if [ -f $BOOT_DIR/tmp/.alcove.binds ]; then
    cat $BOOT_DIR/tmp/.alcove.binds | while read SRC_PNT MNT_PNT; do
      umount $BOOT_DIR/$MNT_PNT;
    done;
  fi;

  if [ -d /data ] && [ -d /sdcard ]; then
    mount -o nosuid,remount /data;
  fi;

  #rm $BOOT_DIR/tmp/.isMounted;
  umount $BOOT_DIR/tmp;
}

alcove_boot()
{
  unset LD_PRELOAD;
  if [ ! -f $BOOT_DIR/etc/.resolv.conf.ok ]; then
    rm -f $BOOT_DIR/etc/resolv.conf;
    echo "nameserver 8.8.4.4" > $BOOT_DIR/etc/resolv.conf;
    echo "nameserver 8.8.8.8" >> $BOOT_DIR/etc/resolv.conf;
    chmod 644 $BOOT_DIR/etc/resolv.conf;
    echo "DNS IS OK" > $BOOT_DIR/etc/.resolv.conf.ok;
  fi;

  [ ! -f $BOOT_DIR/init.sh ] && {
    echo "Not found [$BOOT_DIR/init.sh]";
    echo "Have you run ${0##*/} init?";
    exit $BOOT_ERROR;
  };


  [ -f $BOOT_DIR/tmp/.isMounted ] && {
    echo "Do not boot a same system twice or more!";
    exit $BOOT_ERROR;
  };

  alcove_mount;
  chroot $BOOT_DIR /init.sh;
  alcove_umount;
}

main()
{
  if [ $# -lt 2 ]; then
    show_help;
    exit $NO_ERROR;
  fi;

  BOOT_DIR=`cd $2; pwd` > /dev/null 2>&1;

  check_env;
  case "$1" in
    "init")
    alcove_init;
    ;;
  "boot")
    alcove_boot;
    ;;
  *)
    show_help;
    exit 0;
    ;;
  esac;
}


main "$@";
