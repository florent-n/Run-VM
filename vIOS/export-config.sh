#!/bin/sh
# You have to make the following command in your IOS
# copy running-config flash2:config.txt
if [ $# -eq 1 ]; then
    rm tmp -Rf
    mkdir tmp
    cp $1 tmp/tmp.img
    mcopy -i tmp/tmp.img@@63S :: tmp
    echo "Files retreived"
    ls -al ./tmp
else
    echo "Usage: $0 File.img"
    echo "File.img must be in DOS/MBR format"
    echo "You can check this with the commande file"
fi