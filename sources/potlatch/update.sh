#!/bin/sh
#
#  Taginfo source: Potlatch
#
#  update.sh DIR
#

set -e

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo -n "Start potlatch: "; date

DATABASE=$DIR/taginfo-potlatch.db

rm -f $DATABASE

echo "Getting resources..."
#if [ -d $DIR/resources ]; then
#    svn update $DIR/resources
#else
#    svn checkout http://svn.openstreetmap.org/applications/editors/potlatch2/resources $DIR/resources
#fi

echo "Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "Running import..."
./import_potlatch.rb $DIR

echo "Running post.sql..."
sqlite3 $DATABASE <post.sql

echo -n "Done potlatch: "; date

