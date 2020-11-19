#!/bin/sh
# VM1 --|
#      SW1 ---- R1 ---- Internet
# VM2 --|

PORT_SOUHAITE=7211
SOCKET=1313

PORT=$((PORT_SOUHAITE-5900))

startup() {
#Create nvram disk
# We cannot change the name file ios_config and ios_config_checksum
#The Frist parameter has to be the startup-config file
cp $1 ios_config.txt
md5sum ios_config.txt | cut -d ' ' -f 1 > ios_config_checksum

###### The following task has to be execute for the first time in your shell ######
#Create empty disk image
#qemu-img create IOSv_startup_config.img 1M
#Execute this script a first time and the vIOS will format the file IOSv_startup_config.img in the right format
#Kill the qemu
#Backup and convert the formated file
#qemu-img convert -O raw IOSv_startup_config.img empty-1M.img
#The empty-1M.img is now a DOS/MBR boot sector file format
###################################################################################

cp empty-1M.img IOSv_startup_config.img
##Add the 2 files needed to the empty image
mcopy -i IOSv_startup_config.img@@63S ios_config.txt ::
mcopy -i IOSv_startup_config.img@@63S ios_config_checksum ::
}

### Start SW1
tunctl -t t_vios_SW_1
ifconfig t_vios_SW_1 0.0.0.0 up
tunctl -t t_vios_SW_2
ifconfig t_vios_SW_2 0.0.0.0 up
tunctl -t t_vios_SW_3
ifconfig t_vios_SW_3 0.0.0.0 up

IMAGE="vIOS/vios_l2-adventerprisek9-m.03.2017.qcow2"
IMG="$PASS/vIOS-rel/vios_l2-adventerprisek9-m.03.2017-rel.img"
MEM=1024
NAME="vIOS-SW1"
UUID=`uuidgen`
TAP1="t_vios_SW_1"
TAP2="t_vios_SW_2"
TAP3="t_vios_SW_3"
MAC_BASE="54:55:00:22:03"
STARTUP_CONFIG="SW1-startup-config.txt"

startup $STARTUP_CONFIG
#create a relative image of the primary disk with the vIOS system to avoid to modify the original image and support many users 
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG

qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu host -smp 1 -m $MEM -uuid $UUID -name $NAME -drive file=$IMG,if=virtio,bus=0,unit=0,cache=none -nographic -nodefaults -no-user-config -rtc base=utc -monitor none -netdev tap,id=net1,ifname=$TAP1,script=no -device e1000,netdev=net1,mac=$MAC_BASE:74 -netdev tap,id=net2,ifname=$TAP2,script=no -device e1000,netdev=net2,mac=$MAC_BASE:75 -netdev tap,id=net3,ifname=$TAP3,script=no -device e1000,netdev=net3,mac=$MAC_BASE:76 -chardev socket,id=char0,host=0.0.0.0,port=$((PORT+5900+3)),server,nowait,telnet,logfile=$NAME.log,mux=on -serial chardev:char0 -drive file=IOSv_startup_config.img,if=virtio,bus=1,unit=1,cache=none -daemonize


##Start R1
tunctl -t t_vios_R_1
ifconfig t_vios_R_1 0.0.0.0 up
tunctl -t t_vios_R_2
ifconfig t_vios_R_2 0.0.0.0 up

IMAGE="vIOS/vios-adventerprisek9-m.qcow2"
IMG="$PASS/vIOS-rel/vios-adventerprisek9-m-rel.img"
MEM=2048
NAME="vIOS-R1"
UUID=`uuidgen`
TAP1="t_vios_R_1"
TAP2="t_vios_R_2"
MAC_BASE="54:55:00:22:04"
STARTUP_CONFIG="R1-startup-config.txt"

startup $STARTUP_CONFIG
#create a relative image of the primary disk with the vIOS system to avoid to modify the original image and support many users 
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG

qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu host -smp 1 -m $MEM -uuid $UUID -name $NAME -drive file=$IMG,if=virtio,bus=0,unit=0,cache=none -nographic -nodefaults -no-user-config -rtc base=utc -monitor none -netdev tap,id=net1,ifname=$TAP1,script=no -device e1000,netdev=net1,mac=$MAC_BASE:74 -netdev tap,id=net2,ifname=$TAP2,script=no -device e1000,netdev=net2,mac=$MAC_BASE:75 -chardev socket,id=char0,host=0.0.0.0,port=$((PORT+5900+3)),server,nowait,telnet,logfile=$NAME.log,mux=on -serial chardev:char0 -drive file=IOSv_startup_config.img,if=virtio,bus=1,unit=1,cache=none -daemonize



















#Start VM1

tunctl -t t_vios_VM1
ifconfig t_vios_VM1 0.0.0.0 up
tunctl -t t_vios_VM2
ifconfig t_vios_VM2 0.0.0.0 up

brctl addbr br-vIOS-VM1
brctl addbr br-vIOS-VM2
brctl addbr br-vIOS-R
ifconfig br-vIOS-VM1 0.0.0.0 up
ifconfig br-vIOS-VM2 0.0.0.0 up
ifconfig br-vIOS-R 0.0.0.0 up

brctl addif br-vIOS-VM1 t_vios_VM1
brctl addif br-vIOS-VM1 t_vios_SW_1

brctl addif br-vIOS-VM2 t_vios_VM2
brctl addif br-vIOS-VM2 t_vios_SW_2

brctl addif br-vIOS-R t_vios_R_1
brctl addif br-vIOS-R t_vios_SW_3

#brctl addif br229 t_vios_R_2

PASS="/usr/local/Virtualize/kvm-image/images"
IMAGE="debian10-20190905.img"
IMG="$PASS/img-rel/debian10-20190905-VM1_vIOS-rel.img"
MEM="512"
NAME="VM_1-vIOS"
uuid=`uuidgen`
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM -name $NAME -hda $IMG -uuid $uuid -nic tap,mac=54:55:00:22:03:70,ifname=t_vios_VM1,script=no -vnc 194.57.105.124:$PORT -daemonize

IMG="$PASS/img-rel/debian10-20190905-VM2_vIOS-rel.img"
NAME="VM_2-vIOS"
uuid=`uuidgen`
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM -name $NAME -hda $IMG -uuid $uuid -nic tap,mac=54:55:00:22:03:71,ifname=t_vios_VM2,script=no -vnc 194.57.105.124:$((PORT+1)) -daemonize



