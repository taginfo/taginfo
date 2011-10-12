#!/bin/sh
#
#  test_tagstats.sh
#

set -e
set -x

DATABASE=taginfo-db.db
OSMFILE=$1

rm -f $DATABASE

sqlite3 $DATABASE <../sources/init.sql
sqlite3 $DATABASE <../sources/db/pre.sql

ulimit -c 1000000000
rm -f core

#./tagstats --left=5.5 --bottom=47 --right=15 --top=55 --width=200 --height=320 $OSMFILE
./tagstats $OSMFILE

