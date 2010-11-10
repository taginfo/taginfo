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

echo -n "Running count... "; date
HERE=`pwd`
cd $DIR
bzcat $DIR/planet.osm.bz2 | $HERE/osmium_tagstats -
cd $HERE

echo -n "Running update_characters... "; date
./update_characters.pl $DIR

echo -n "Running post.sql... "; date
perl -pe "s|__DIR__|$DIR|" post.sql | sqlite3 $DATABASE

echo -n "Done db: "; date

