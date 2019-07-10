#!/bin/sh
umask 022;
echo 'Debug::NoDropPrivs true;' > /etc/apt/apt.conf.d/00no-drop-privs;

