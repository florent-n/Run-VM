#!/bin/sh
# VM1 --|
#      SW ---- R ---- Internet
# VM2 --|

PORT_SOUHAITE=7211
SOCKET=1313

PORT=$((PORT_SOUHAITE-5900))

tunctl -t t_vios_VM1
ifconfig t_vios_VM1 0.0.0.0 up
tunctl -t t_vios_VM2
ifconfig t_vios_VM2 0.0.0.0 up
tunctl -t t_vios_R_1
ifconfig t_vios_R_1 0.0.0.0 up
tunctl -t t_vios_R_2
ifconfig t_vios_R_2 0.0.0.0 up
tunctl -t t_vios_SW_1
ifconfig t_vios_SW_1 0.0.0.0 up
tunctl -t t_vios_SW_2
ifconfig t_vios_SW_2 0.0.0.0 up
tunctl -t t_vios_SW_3
ifconfig t_vios_SW_3 0.0.0.0 up

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

brctl addif br229 t_vios_R_2

PASS="/usr/local/Virtualize/kvm-image/images"
IMAGE="debian10-20190905.img"
IMG="$PASS/img-rel/debian10-20190905-VM1_vIOS-rel.img"
MEM="512"
NAME="VM_1-vIOS"
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM -name $NAME -hda $IMG -nic tap,mac=54:55:00:22:03:70,ifname=t_vios_VM1,script=no -vnc 194.57.105.124:$PORT -daemonize

IMG="$PASS/img-rel/debian10-20190905-VM2_vIOS-rel.img"
NAME="VM_2-vIOS"
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM -name $NAME -hda $IMG -nic tap,mac=54:55:00:22:03:71,ifname=t_vios_VM2,script=no -vnc 194.57.105.124:$((PORT+1)) -daemonize

IMAGE="vIOS/vios-adventerprisek9-m.qcow2"
IMG="$PASS/vIOS-rel/vios-adventerprisek9-m-rel.img"
MEM=2048
NAME="vIOS-R1"
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -serial none -nographic -nodefaults -display none -vga std -no-shutdown -smp 1 -m $MEM -name $NAME -drive file=$IMG,if=virtio,bus=0,unit=0,cache=none -nic tap,mac=54:55:00:22:03:72,ifname=t_vios_R_1,script=no -nic tap,mac=54:55:00:22:03:73,ifname=t_vios_R_2,script=no -serial telnet:0.0.0.0:$((PORT+5900+2)),server,nowait -daemonize

IMAGE="vIOS/vios_l2-adventerprisek9-m.03.2017.qcow2"
IMG="$PASS/vIOS-rel/vios_l2-adventerprisek9-m.03.2017-rel.img"
MEM=2048
NAME="vIOS-SW1"
qemu-img create -b $PASS/$IMAGE -f qcow2 $IMG
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -name $NAME -serial none -nographic -nodefaults -display none -vga std -no-shutdown -smp 1 -m $MEM  -drive file=$IMG,if=virtio,bus=0,unit=0,cache=none -nic tap,mac=54:55:00:22:03:74,ifname=t_vios_SW_1,script=no -nic tap,mac=54:55:00:22:03:75,ifname=t_vios_SW_2,script=no -nic tap,mac=54:55:00:22:03:76,ifname=t_vios_SW_3,script=no -serial telnet:0.0.0.0:$((PORT+5900+3)),server,nowait -daemonize



