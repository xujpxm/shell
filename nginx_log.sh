#!/bin/bash
logdir="/data/nginx/logs"
pid=`cat /var/run/nginx.pid`
DATE=`date -d "30 min ago" +%Y%m%d%H%M`
for i in `ls $logdir/*.log`; do
        mv $i $i.$DATE
done
kill -s USR1 $pid

for j in $(ls $logdir/*.$DATE); do
        [ ! -s $j ] && rm -f $j || gzip $j
done
[ -d /data/nginx/logs ] && find /data/nginx/logs/ -type f -atime +30 -exec rm -f {} \;
