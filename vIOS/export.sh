#!/bin/sh
#You have to make the following command in your IOS
# copy running-config flash2:config.txt

rm tmp -Rf
mkdir tmp
cp IOSv_startup_config.img tmp/tmp.img
mcopy -i tmp/tmp.img@@63S :: tmp
echo "Files retreived"
ls -al ./tmp
