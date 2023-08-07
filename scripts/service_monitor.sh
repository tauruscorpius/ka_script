#!/bin/bash

exestage="$1"

workdir=$(dirname $0)
. $workdir/var.sh

if [ "x$ka_vip" = "x" ]; then
 echo "miss ka_vip @$workdir/var.sh"
 exit -1
fi

if [ "x$ka_service" = "x" ]; then
 echo "miss ka_service @$workdir/var.sh"
 exit -1
fi

monitor_log_dir=/var/log/keepalived
today=`date "+%Y%m%d"`
monitor_log_file=$monitor_log_dir/service_${ka_service}_monitor_${today}.log
retry_times_file=/etc/keepalived/.service_${ka_service}_retry_times
mkdir -p $monitor_log_dir

retry_times=0

baseName=$(basename $0)
pid_file=/tmp/service_monitor_${baseName}.pid

if [ -e $pid_file ]; then
  pid_instance=`cat $pid_file 2>/dev/null|tail -n 1`
  echo "previous instance exist, instance file: " >> $monitor_log_file
  cat $pid_file >> $monitor_log_file
  echo "instance pid to check : kill -0 $pid_instance" >> $monitor_log_file
  kill -0 $pid_instance  
  if [ $? = 0 ]; then
    echo "previous instance pid $pid_instance alived, so exit" >> $monitor_log_file
    exit -2
  fi
  echo "previous instance pid $pid_instance died, so continue" >> $monitor_log_file
fi

echo $$ > ${pid_file}
trap "rm -rf ${pid_file}; exit 0" HUP INT QUIT FPE KILL TERM

function chk_vip()
{
  arg=$1
  if [ "x$arg" = "x" ]; then
    echo "mis"
    return
  fi
  vip=`/sbin/ip a show|grep inet|sed 's/^\s*inet\w*\s*//g'|sed 's/\/.*//g'`
  echo "list ips : $vip" >> $monitor_log_file
  for i in $vip;
  do
    echo "$i ?= $arg" >> $monitor_log_file
    if [ "x$i" = "x$arg" ]; then
      echo "yes"
      return
    fi
  done
  echo "no"
}

function get_app_service_status()
{
  arg=$1
  if [ "x$arg" = "x" ]; then
    echo "missArg"
    return
  fi
  sstatus=`systemctl status $arg 2>/dev/null|grep Active|sed 's/^\s*Active:\s//g'|head -n 1|sed 's/\s.*//g'`
  echo ${sstatus:0:6}
}

svc_start_waiting_duration=1
if [ $ka_service_start_duration -gt 1 ] && [ $ka_service_start_duration -lt 10 ] 2>/dev/null; then
 svc_start_waiting_duration=$ka_service_start_duration
fi

ka_system_start_delay=1
if [ $ka_system_delay -gt 1 ] && [ $ka_system_delay -lt 120 ] 2>/dev/null; then
 ka_system_start_delay=$ka_system_delay
fi

date >> $monitor_log_file
echo "monitor start, using stage: $exestage" >>  $monitor_log_file

if [ "x$exestage" = "xboot" ]; then
  echo "system boot, sleep $ka_system_start_delay ..." >>  $monitor_log_file
  sleep $ka_system_start_delay
  date >> $monitor_log_file
  echo "boot keepalived, make it active" >>  $monitor_log_file
  $workdir/tool_start_keepalived.sh
fi

while [ 1 ];
do

is=$(chk_vip "$ka_vip")

date >> $monitor_log_file
echo "find vip $ka_vip @ localhost : $is" >> $monitor_log_file

kastatus=$(get_app_service_status "keepalived")
echo "keepalived Active status : [$kastatus]" >> $monitor_log_file

tstatus=$(get_app_service_status "$ka_service")
echo "service $ka_service Active status : [$tstatus] retryTimes[$retry_times]" >> $monitor_log_file

if [ "x$is" = "xyes" ]; then
  if [ "x$tstatus" != "xactive" ]; then
    # start 
    systemctl start $ka_service 
    echo "start $ka_service service, and waiting $svc_start_waiting_duration second to completed" >> $monitor_log_file
    sleep $svc_start_waiting_duration
    let retry_times=$retry_times+1
    echo $retry_times >> $retry_times_file
  else
    retry_times=0
    echo $retry_times > $retry_times_file
  fi
else
  retry_times=0
  echo $retry_times > $retry_times_file
  if [ "x$tstatus" = "xactive" ]; then
     # stop
     systemctl stop $ka_service
     echo "stop $ka_service service" >> $monitor_log_file
  fi
fi


sleep 1

done
