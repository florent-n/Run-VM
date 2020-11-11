#!/bin/sh
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
echo "Usage: $0 num_port -r";
echo "(required) num_port : port de la VM à démarrer";
echo "(option) -r : redémarrage de la VM à partir de son image d'origine";
exit
else
if [ $# -eq 2 ]; then 
	if [ $2 = '-r' ]; then 
		reboot=true
	fi
fi

cmd=$0
Wanted_port=$1

#NB=25
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

delete_tap () {
	ip link set down dev t_$1
	ip link delete dev t_$1
}

tp_number=$(((Wanted_port-$WEBSOCKET_PORT-1)/4+1))
br_interface="Info0305-$tp_number"
i=$((Wanted_port-$WEBSOCKET_PORT))
j=$((Wanted_port-$WEBSOCKET_PORT))
#net=1
#net=$(((Wanted_port-$WEBSOCKET_PORT+1)/3+1))

MEM_IMG1=2G
MEM_IMG2=256
#MEM_IMG4=256
MEM_IMG3=256
MEM_IMG4=2G

IMG1=$PASS/img-rel/Linux-Lite-Info0305-rel-$tp_number-1.img
IMG2=$PASS/img-rel/debian10-20190905-Info0305-rel-$tp_number-2.img
IMG3=$PASS/img-rel/debian10-20190905-Info0305-rel-$tp_number-3.img
IMG4=$PASS/img-rel/Linux-Lite-Info0305-rel-$tp_number-4.img

RESULT=`echo $(((i-1)%4 )) |bc`;

proc=`ps -ef | grep qemu |grep $Wanted_port | grep -v grep | awk '{print $2}'`
i=$(((tp_number-1)*6+1))
mynet_num=$((i+RESULT))
#echo "proc:$proc"
#echo "nb_tp:$tp_number"
#echo "mynet num : $mynet_num"
#echo "j:$j"
#echo "PC num ? result:$RESULT"

if [ $proc ]; then
echo "Stop VM on port $Wanted_port"
kill $proc
sleep 3
fi

case $RESULT in
	0)
NAME="35-$tp_number-PC1"
echo "Starting $NAME"
if [ $reboot ]; then
qemu-img create -b $PASS/$IMAGE1 -f qcow2 $IMG1
fi
delete_tap $NAME
create_tap $NAME
#ovs-vsctl add-port ${br_interface} t_$NAME tag=2
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG1 -hda $IMG1 -device e1000,netdev=mynet$mynet_num,mac=${MAC}$(printf %02x $mynet_num) -monitor none -netdev tap,ifname=t_$NAME,id=mynet$i,script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -smp 2 -daemonize
		;;
	1)
NAME="35-$tp_number-PC2"
echo "Starting $NAME"
if [ $reboot ]; then
qemu-img create -b $PASS/$IMAGE2 -f qcow2 $IMG2
fi
delete_tap ${NAME}_1
delete_tap ${NAME}_2
create_tap ${NAME}_1
#ovs-vsctl add-port ${br_interface} t_${NAME}_1 tag=2
create_tap ${NAME}_2
#ovs-vsctl add-port ${br_interface} t_${NAME}_2 tag=3
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG2 -hda $IMG2 -device e1000,netdev=mynet$((mynet_num)),mac=${MAC}$(printf %02x $mynet_num) -monitor none -netdev tap,ifname=t_${NAME}_1,id=mynet$((mynet_num)),script=no -device e1000,netdev=mynet$((mynet_num+1)),mac=${MAC}$(printf %02x $((mynet_num+1))) -netdev tap,ifname=t_${NAME}_2,id=mynet$((mynet_num+1)),script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -daemonize
		;;
	2)
NAME="35-$tp_number-PC3"
echo "Starting $NAME"
if [ $reboot ]; then
qemu-img create -b $PASS/$IMAGE3 -f qcow2 $IMG3
fi
delete_tap ${NAME}_1
delete_tap ${NAME}_2
create_tap ${NAME}_1
#ovs-vsctl add-port ${br_interface} t_${NAME}_1 tag=3
create_tap ${NAME}_2
#ovs-vsctl add-port ${br_interface} t_${NAME}_2 tag=4
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG3 -hda $IMG3 -device e1000,netdev=mynet$((mynet_num+1)),mac=${MAC}$(printf %02x $((mynet_num+1))) -monitor none -netdev tap,ifname=t_${NAME}_1,id=mynet$((mynet_num+1)),script=no -device e1000,netdev=mynet$((mynet_num+2)),mac=${MAC}$(printf %02x $((mynet_num+2))) -netdev tap,ifname=t_${NAME}_2,id=mynet$((mynet_num+2)),script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -daemonize
		;;
	3)
NAME="35-$tp_number-PC4"
echo "Starting $NAME"
if [ $reboot ]; then
qemu-img create -b $PASS/$IMAGE4 -f qcow2 $IMG4
fi
delete_tap $NAME
create_tap $NAME
#ovs-vsctl add-port ${br_interface} t_$NAME tag=4
qemu-system-x86_64 -enable-kvm -machine accel=kvm:tcg -cpu max -m $MEM_IMG4 -hda $IMG4 -device e1000,netdev=mynet$((mynet_num+2)),mac=${MAC}$(printf %02x $((mynet_num+2))) -monitor none -netdev tap,ifname=t_$NAME,id=mynet$((mynet_num+2)),script=no -vnc 0.0.0.0:$((VNC_PORT+$j-5900)),websocket=$((WEBSOCKET_PORT+$j)) -name Info$NAME -vga qxl -usb -device usb-tablet -k fr -smp 2 -daemonize
		;;
	*)	echo "fin"
		;;
esac
fi
