#!/bin/bash -x

workdir=$(dirname $0)
. $workdir/var.sh

if [ "x$ka_interface" = "x" ]; then
 echo "miss ka_service @$workdir/var.sh"
 exit -2
fi

if [ "x$ka_gateway" = "x" ]; then
 echo "miss ka_service @$workdir/var.sh"
 exit -3
fi


if [ $# -lt 1 ]; then
  echo "usage: $0 master|backup"
  exit -1
fi
status=$1

notify_log_dir=/var/log/keepalived
today=`date "+%Y%m%d"`
notify_notify_file=$notify_log_dir/service_${ka_service}_notify_${today}.log

date >> $notify_notify_file
echo $status >> $notify_notify_file
ip a >> $notify_notify_file
if [ "x$status" = "xmaster" ]; then
  /sbin/arping -I $ka_interface -c 5 -s $ka_vip $ka_gateway 
fi

# keepalived first status is backup when start
#
#if [ "x$status" = "xbackup" ]; then
#  # stop
#  systemctl stop $ka_service
#  echo "stop $ka_service service" >> $notify_notify_file
#fi
