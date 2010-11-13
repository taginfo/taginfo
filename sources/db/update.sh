#!/bin/sh
#
#  Taginfo source: DB
#
#  update.sh DIR
#

set -e

DIR=$1

DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo "`$DATECMD` Start db..."

DATABASE=$DIR/taginfo-db.db

rm -f $DATABASE
rm -f $DIR/count.db

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Running count... "
HERE=`pwd`
cd $DIR
bzcat $DIR/planet.osm.bz2 | $HERE/osmium_tagstats -
cd $HERE

echo "`$DATECMD` Running update_characters... "
./update_characters.pl $DIR

echo "`$DATECMD` Running post.sql... "
perl -pe "s|__DIR__|$DIR|" post.sql | sqlite3 $DATABASE

echo "`$DATECMD` Done db."

