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
SELECTION_DB=selection.db
#IMAGE_OPTIONS="--left=5.5 --bottom=47 --right=15 --top=55 --width=200 --height=320"

rm -f $DATABASE

sqlite3 $DATABASE <../sources/init.sql
sqlite3 $DATABASE <../sources/db/pre.sql

#ulimit -c unlimited
rm -f core.*

if [ -f $SELECTION_DB ]; then
    selection_option="--selection-db=$SELECTION_DB"
else
    selection_option=""
fi

./tagstats $selection_option --min-tag-combination-count=100 $IMAGE_OPTIONS $OSMFILE $DATABASE

