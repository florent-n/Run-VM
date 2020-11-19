#!/bin/sh
# VM1 --|
#      SW1 ---- R1 ---- Internet
# VM2 --|

PORT_DEBUT=7211
PASS="/usr/local/Virtualize/kvm-image/images"

startup() {
#Create nvram disk
# We cannot change the name file ios_config and ios_config_checksum
#First parameter has to be the startup-config file
STARTFILE=$1
#Second parameter is the file used as a second drive for the vIOS 
DRIVEIMG=$2
echo "The STARTFILE is $STARTFILE"
echo "The DRIVEIMG is $DRIVEIMG"

if [ ! -f $DRIVEIMG ]; then
    qemu-img create $DRIVEIMG 1M
    echo "YOU MUST EXEC A Stop-Vm-vIOS.sh AFTER YOUR EQUIPMENTS HAVE FINISHED TO BOOT AND FORMAT THE FILE $DRIVEIMG"
    echo "AFTER THE Stop-VM-vIOS.sh YOU MUST EXECUTE THE FOLLOGIN COMMAND"
    echo "qemu-img convert -O raw $DRIVEIMG drive_file_ready.img"
    echo "The drive_file_ready.img is now a DOS/MBR boot sector"
fi

if [ -f $STARTFILE ]; then
    cp $STARTFILE ios_config.txt
    md5sum ios_config.txt | cut -d ' ' -f 1 > ios_config_checksum
    if [ -f drive_file_ready.img ]; then
        cp drive_file_ready.img $DRIVEIMG
    
        ##Add the 2 files needed to the empty image
        mcopy -i $DRIVEIMG@@63S ios_config.txt ::
        mcopy -i $DRIVEIMG@@63S ios_config_checksum ::
    fi
fi
#To automatized a record of the running-config in the drive $DRIVEIMG, you have to add to your configuration the following line
#Each time you will make a copy run start, a backup of the start will be copy on the $DRIVEIMG and you will be able to extract it with the export.sh script
# archive
#   path flash2:config.txt
#   write-memory
#
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
SECOND_DRIVE="$NAME"_startup.img
PORT=$((PORT_DEBUT))

startup $STARTUP_CONFIG $SECOND_DRIVE
#create a relative image of the primary disk with the vIOS system to avoid to modify the original image and support many users 
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG

qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu host -smp 1 -m $MEM -uuid $UUID -name $NAME -drive file=$IMG,if=virtio,bus=0,unit=0,cache=none -nographic -nodefaults -no-user-config -rtc base=utc -monitor none -netdev tap,id=net1,ifname=$TAP1,script=no -device e1000,netdev=net1,mac=$MAC_BASE:74 -netdev tap,id=net2,ifname=$TAP2,script=no -device e1000,netdev=net2,mac=$MAC_BASE:75 -netdev tap,id=net3,ifname=$TAP3,script=no -device e1000,netdev=net3,mac=$MAC_BASE:76 -chardev socket,id=char0,host=0.0.0.0,port=$PORT,server,nowait,telnet,logfile=$NAME.log,mux=on -serial chardev:char0 -drive file=$SECOND_DRIVE,if=virtio,bus=1,unit=1,cache=none,format=raw -daemonize
echo "$NAME started and listen on port $PORT"

##Start R1
tunctl -t t_vios_R_1
ifconfig t_vios_R_1 0.0.0.0 up
tunctl -t t_vios_R_2
ifconfig t_vios_R_2 0.0.0.0 up

IMAGE="vIOS/vios-adventerprisek9-m.qcow2"
IMG="$PASS/vIOS-rel/vios-adventerprisek9-m-rel.img"
MEM=2048
NAME="vIOS-R1"
TAP1="t_vios_R_1"
TAP2="t_vios_R_2"
MAC_BASE="54:55:00:22:04"
STARTUP_CONFIG="R1-startup-config.txt"
SECOND_DRIVE="$NAME"_startup.img
PORT=$((PORT+1))

startup $STARTUP_CONFIG $SECOND_DRIVE
UUID=`uuidgen`
#create a relative image of the primary disk with the vIOS system to avoid to modify the original image and support many users 
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu host -smp 1 -m $MEM -uuid $UUID -name $NAME -drive file=$IMG,if=virtio,bus=0,unit=0,cache=none -nographic -nodefaults -no-user-config -rtc base=utc -monitor none -netdev tap,id=net1,ifname=$TAP1,script=no -device e1000,netdev=net1,mac=$MAC_BASE:74 -netdev tap,id=net2,ifname=$TAP2,script=no -device e1000,netdev=net2,mac=$MAC_BASE:75 -chardev socket,id=char0,host=0.0.0.0,port=$PORT,server,nowait,telnet,logfile=$NAME.log,mux=on -serial chardev:char0 -drive file=$SECOND_DRIVE,if=virtio,bus=1,unit=1,cache=none,format=raw -daemonize
echo "$NAME started and listen on port $PORT"

#Start VM1
tunctl -t t_vios_VM1
ifconfig t_vios_VM1 0.0.0.0 up

PASS="/usr/local/Virtualize/kvm-image/images"
IMAGE="debian10-20190905.img"
IMG="$PASS/img-rel/debian10-20190905-VM1_vIOS-rel.img"
MEM="512"
NAME="VM_1-vIOS"
TAP1="t_vios_VM1"
MAC_BASE="54:55:00:22:05"
PORT=$((PORT+1))

UUID=`uuidgen`
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM -name $NAME -hda $IMG -uuid $UUID -nic tap,mac=$MAC_BASE:01,ifname=$TAP1,script=no -vnc 194.57.105.124:$((PORT-5900)) -daemonize
echo "$NAME started and listen on port $PORT"
#Start VM2
tunctl -t t_vios_VM2
ifconfig t_vios_VM2 0.0.0.0 up

IMG="$PASS/img-rel/debian10-20190905-VM2_vIOS-rel.img"
NAME="VM_2-vIOS"
TAP1="t_vios_VM2"
MAC_BASE="54:55:00:22:06"
PORT=$((PORT+1))

UUID=`uuidgen`
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM -name $NAME -hda $IMG -uuid $UUID -nic tap,mac=$MAC_BASE:02,ifname=$TAP1,script=no -vnc 194.57.105.124:$((PORT-5900)) -daemonize
echo "$NAME started and listen on port $PORT"

#Build the network between all devices
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
