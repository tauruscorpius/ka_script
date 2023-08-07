#!/bin/bash 


monitor_process=`ps -ef|grep -w $LOGNAME|grep -v grep|grep -w service_monitor\.sh|awk '{print $2}'`

if [ "x$monitor_process" != "x" ]; then
  kill $monitor_process
fi
