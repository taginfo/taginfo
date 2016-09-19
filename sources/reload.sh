#!/bin/bash

LOG=/mnt/data/taginfo/log/web-`date +"%Y.%m.%d"`.log

. /usr/local/bin/profile

P=`ps -C 'ruby taginfo.rb' --no-headers -o pid 2>/dev/null`

test -n "$P" && {
 kill $P
 sleep 1s #wait for port to cleanup
}

cd $HOME/taginfo.git/web/ || exit
nohup ./taginfo.rb 4567 >>$LOG 2>&1 &
