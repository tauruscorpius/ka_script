#!/bin/bash -x


workdir=$(dirname $0)
. $workdir/var.sh

retry_times=3

if [ "x$ka_service" = "x" ]; then
 echo "miss ka_service @$workdir/var.sh"
 exit 0
fi


if [ $ka_retry_times -gt 1 ] && [ $ka_retry_times -lt 5 ] 2>/dev/null; then
 retry_times=$ka_retry_times
fi

retry_times_file=/etc/keepalived/.service_${ka_service}_retry_times

times=`cat $retry_times_file 2>/dev/null|tail -n 1`

if [ "x$times" = "x" ]; then
  exit 0
fi


if [ $times -gt $ka_retry_times ]; then
  exit 1
fi


exit 0

