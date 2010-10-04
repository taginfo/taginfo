#!/bin/sh
#
#  Taginfo source: JOSM
#
#  update.sh DIR
#

set -e

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo -n "Start josm: "; date

DATABASE=$DIR/taginfo-josm.db
ELEMSTYLES=$DIR/elemstyles.xml

rm -f $DATABASE
rm -f $ELEMSTYLES

echo "Getting styles..."
wget -O $ELEMSTYLES http://josm.openstreetmap.de/svn/trunk/styles/standard/elemstyles.xml

echo "Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "Running import..."
./import_josm.rb $DIR

echo "Running post.sql..."
sqlite3 $DATABASE <post.sql

echo -n "Done josm: "; date

