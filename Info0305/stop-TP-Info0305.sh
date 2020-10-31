#!/bin/sh
for i in `ps -ef | grep qemu |grep "t_35-" | grep -v grep | awk '{print $2}'`; do kill -9 $i; done
sleep 5
for i in `ip link show | grep "t_35-" |grep -v grep | awk '{print $2}' | cut -d":" -f 1`; do ip tuntap del $i mode tap; done
for i in `ip link show | grep "Info0305-" |grep -v grep | awk '{print $2}' | cut -d":" -f 1`; do ovs-vsctl del-br $i; done
if [ -f Run-Vm-Info0305.sh.txt ]; then
	for i in `cat Run-Vm-Info0305.sh.txt`; do ovs-vsctl del-br $i; done
fi
