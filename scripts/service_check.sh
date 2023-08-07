#!/bin/bash 


workdir=$(dirname $0)
. $workdir/var.sh

if [ "x$ka_service" = "x" ]; then
 echo "miss ka_service @$workdir/var.sh"
 exit -2 
fi

hbt_log_dir=/var/log/keepalived
today=`date "+%Y%m%d"`
hbt_log_file=$hbt_log_dir/service_${ka_service}_hbt_${today}.log
mkdir -p $hbt_log_dir

date >> $hbt_log_file

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

status=$(get_app_service_status "$ka_service")

if [ "x$status" != "xactive" ]; then
  echo "service <$ka_service> inactive" >> $hbt_log_file
  exit -1
fi

echo "service <$ka_service> active" >> $hbt_log_file

exit 0

