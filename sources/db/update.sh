#!/bin/sh
#
#  Taginfo source: DB
#
#  update.sh DIR
#

set -e

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo -n "Start db: "; date

DATABASE=$DIR/taginfo-db.db

rm -f $DATABASE
rm -f $DIR/count.db

echo "Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "Running count..."
HERE=`pwd`
cd $DIR
bzcat $DIR/planet.osm.bz2 | $HERE/osmium_tagstats -
cd $HERE

echo "Running update_characters..."
./update_characters.pl $DIR

echo "Running post.sql..."
perl -pe "s|__DIR__|$DIR|" post.sql | sqlite3 $DATABASE

echo -n "Done db: "; date

