Alcove.sh
============

Yet Another chroot script to run Linux on Android.


## Usage ##
```sh
#
# Assume you use this script on Android
#

# Switch to root(aka superuser)
su -;

# Make /system readable
mount -o rw,remount /system;

# install alcove.sh to /system
cp alcove.sh /system/xbin/alcove;

# Make /system readonly(Optional)
mount -o ro,remount /system;

# Create new root directory
mkdir /data/debian;

# Enter the new root directory
cd /data/debian;

# Download rootfs.tar.{bz,gz,xz}
# For example, download a debian rootfs
wget http://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/buster/arm64/default/20190709_15%3A39/rootfs.tar.xz;

# Extract(or Unpack) rootfs.tar.{bz,gz,xz}
tar xvpf rootfs.tar.xz;

# Go back to parent directory(Optional)
cd ../;

# Initial new root directory
alcove init /data/debian;

# Boot the new system
alcove boot /data/debian;
```

## How to boot? ##
If you didn't installed any system before, you may go back to top read the usage to learn how to install a system. If you have installed and initiated a system, you can simply just use alcove boot **/path/to/system-directory** to boot it.

## Requires ##
  - Rooted(Android)
  - Busybox(or toybox)

## Patches List ##
See [patches](./patches)

