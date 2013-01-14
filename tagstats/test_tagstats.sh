#!/bin/sh
#
#  test_tagstats.sh OSMFILE
#
#  This is a little helper program to test the function of tagstats.
#  Its not supposed to be used in production.
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

#./tagstats --left=5.5 --bottom=47 --right=15 --top=55 --width=200 --height=320 $OSMFILE $DATABASE
./tagstats --tags test_tags.txt --relation-types test_relation_types.txt $OSMFILE $DATABASE

