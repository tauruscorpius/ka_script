#!/bin/bash

workdir=$(dirname $0)
. $workdir/var.sh

nohup $workdir/service_monitor.sh $* 2>&1 >/dev/null &
