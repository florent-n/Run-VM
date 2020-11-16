#!/bin/sh

PORT_SOUHAITE=7211
SOCKET=1313

PORT=$((PORT_SOUHAITE-5900))

for i in `ps -ef | grep qemu |grep "vIOS" | grep -v grep | awk '{print $2}'`; do kill -9 $i; done
sleep 5
for i in `ip link show | grep "t_vios" |grep -v grep | awk '{print $2}' | cut -d":" -f 1`; do ip tuntap del $i mode tap; done
for i in `brctl show | grep "br-vIOS" |grep -v grep | awk '{print $1}' | cut -d":" -f 1`; do ip link set down dev $i; brctl delbr $i; done

