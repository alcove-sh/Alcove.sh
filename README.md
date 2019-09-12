Alcove.sh
==================

Yet Another chroot script to run Linux on Android.


## Usage ##
1. mkdir alpine && cd alpine

2. wget -O - http://mirrors.ustc.edu.cn/alpine/v3.10/releases/aarch64/alpine-minirootfs-3.10.0-aarch64.tar.gz | tar xzvpf -

3. cd ../ && alcove init alpine

4. alcove boot alpine


## How to boot? ##
If you didn't installed any system before, you may go back to top read the usage to learn how to install a system. If you have installed and initiated a system, you can simply just use `alcove boot **/path/to/system-directory**` to boot it.

## Requirement ##
  - Rooted(Android)
  - Busybox(or toybox)

## Patch List ##
See [patches](./patches)

## Alcove.binds ##
alcove.binds is a fstab-like file to bind host directory/file to **NEWROOT**'s directory/file.

For example:
```fstab
# Syntax:
#   source_dir  newroot_dir
#   Use '#' at begin of a line to comment it.

# sdcard
/sdcard  /mnt/intsd
```

## Event-Hooks ##
Event-Hooks is a little daemon manager for chroot-environment. To use it you need just create new directory named alcove-hooks in **NEWROOT**(/alcove-hooks). There are only two events for the *script which under the /alcove-hooks*, **start** and **stop**.

Also it is similar to other SysvInit scripts. They are created because there are too many Linux distribution use systemd to replace init.d etc, but it cannot work on chroot-environment.

We have two good and standard examples for you, click [00-extsd](hooks/common/00-extsd) and [22-sshd](hooks/common/22-sshd) to see. 

## Non-Root Edition ##
See [linux-on-termux](https://github.com/uzilla/linux-on-termux)


Note: The patch of apt just copy from [LinuxDeploy](https://github.com/meefik/linuxdeploy-cli/blob/5f18caf3fa8c4760a8e79287384e14d69b19e56c/include/bootstrap/ubuntu/deploy.sh#L32), so special thanks to meefik!

## License ##
```license
MIT License

Copyright (c) 2018-2019 urain39 & Kyono

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
