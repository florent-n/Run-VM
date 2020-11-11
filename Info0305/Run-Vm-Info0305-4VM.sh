#!/bin/sh
if [ ! $# -eq 1 ]; then
echo "Usage: $0 #groupe";
exit
else

Data_File=$0
NB=$1
WEBSOCKET_PORT=6970
VNC_PORT=10970

WEBSOCKET="/home/fnolot/"
PASS="/usr/local/Virtualize/kvm-image/images"
IMAGE1="/Linux-Lite-Info0305.img"
IMAGE2="/debian10-20190905.img"
IMAGE3="/debian10-20190905.img"
IMAGE4="/Linux-Lite-Info0305.img"
MAC="00:18:DE:10:13:"

create_tap () {
	ip tuntap add dev t_$1 mod tap
	ip link set up dev t_$1
}

#Stop all existing 
echo "Kill all previous VM and switch"
./stop-TP-Info0305.sh
echo "Start all VMs"
tp_number=1; #The number of the group
i=1; #the number of the network
j=1; #the console port 
last_mac=1; #The last octet of the MAC
net=1;

MEM_IMG1=2G
MEM_IMG2=256
#MEM_IMG4=256
MEM_IMG3=256
MEM_IMG4=2G

if [ -f $Data_File.txt ]; then
	rm $Data_File.txt
fi


while [ $tp_number -le $NB ]
do
br_interface="Info0305-$tp_number"
echo $br_interface >> $Data_File.txt
ovs-vsctl add-br ${br_interface}
ip link set up dev ${br_interface}

IMG1=$PASS/img-rel/Linux-Lite-Info0305-rel-$tp_number-1.img
IMG2=$PASS/img-rel/debian10-20190905-Info0305-rel-$tp_number-2.img
IMG3=$PASS/img-rel/debian10-20190905-Info0305-rel-$tp_number-3.img
IMG4=$PASS/img-rel/Linux-Lite-Info0305-rel-$tp_number-4.img

#qemu-img create -b $PASS/$IMAGE1 -f qcow2 $IMG1
#qemu-img create -b $PASS/$IMAGE2 -f qcow2 $IMG2
#qemu-img create -b $PASS/$IMAGE3 -f qcow2 $IMG3
#qemu-img create -b $PASS/$IMAGE4 -f qcow2 $IMG4

NAME="35-$tp_number-PC1"
create_tap $NAME // Create a tap with the name t_$NAME
ovs-vsctl add-port ${br_interface} t_$NAME tag=2
echo "Starting $NAME"
#qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG1 -hda $IMG1 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $last_mac) -monitor none -netdev tap,ifname=t_$NAME,id=mynet$i,script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -smp 2 -daemonize
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG1 -hda $IMG1 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $last_mac) -monitor none -netdev tap,ifname=t_$NAME,id=mynet$i,script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -smp 2 -daemonize
sleep 5
i=$((i+1));
j=$((j+1));
last_mac=$((last_mac+1));

NAME="35-$tp_number-PC2"
create_tap ${NAME}_1
ovs-vsctl add-port ${br_interface} t_${NAME}_1 tag=2
create_tap ${NAME}_2
ovs-vsctl add-port ${br_interface} t_${NAME}_2 tag=3
echo "Starting $NAME"
#qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG2 -hda $IMG2 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $last_mac) -monitor none -netdev tap,ifname=t_${NAME}_1,id=mynet$((i)),script=no -device e1000,netdev=mynet$((i+1)),mac=${MAC}$(printf %02x $((last_mac+1))) -netdev tap,ifname=t_${NAME}_2,id=mynet$((i+1)),script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -daemonize
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG2 -hda $IMG2 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $last_mac) -monitor none -netdev tap,ifname=t_${NAME}_1,id=mynet$((i)),script=no -device e1000,netdev=mynet$((i+1)),mac=${MAC}$(printf %02x $((last_mac+1))) -netdev tap,ifname=t_${NAME}_2,id=mynet$((i+1)),script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -daemonize
sleep 5
i=$((i+2));
j=$((j+1));
last_mac=$((last_mac+2));

NAME="35-$tp_number-PC3"
create_tap ${NAME}_1
ovs-vsctl add-port ${br_interface} t_${NAME}_1 tag=3
create_tap ${NAME}_2
ovs-vsctl add-port ${br_interface} t_${NAME}_2 tag=4
echo "Starting $NAME"
#qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG3 -hda $IMG3 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $last_mac) -monitor none -netdev tap,ifname=t_${NAME}_1,id=mynet$((i)),script=no -device e1000,netdev=mynet$((i+1)),mac=${MAC}$(printf %02x $((last_mac+1))) -netdev tap,ifname=t_${NAME}_2,id=mynet$((i+1)),script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -daemonize
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG3 -hda $IMG3 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $last_mac) -monitor none -netdev tap,ifname=t_${NAME}_1,id=mynet$((i)),script=no -device e1000,netdev=mynet$((i+1)),mac=${MAC}$(printf %02x $((last_mac+1))) -netdev tap,ifname=t_${NAME}_2,id=mynet$((i+1)),script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -daemonize
sleep 5
i=$((i+2));
j=$((j+1));
last_mac=$((last_mac+2));

NAME="35-$tp_number-PC4"
create_tap $NAME
ovs-vsctl add-port ${br_interface} t_$NAME tag=4
echo "Starting $NAME"
#qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG4 -hda $IMG4 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $((last_mac))) -monitor none -netdev tap,ifname=t_$NAME,id=mynet$i,script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -smp 2 -daemonize
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG4 -hda $IMG4 -device e1000,netdev=mynet$((i)),mac=${MAC}$(printf %02x $((last_mac))) -monitor none -netdev tap,ifname=t_$NAME,id=mynet$i,script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -smp 2 -daemonize
sleep 5
i=$((i+1));
j=$((j+1));
last_mac=$((last_mac+1));
tp_number=$((tp_number+1));

done
fi
