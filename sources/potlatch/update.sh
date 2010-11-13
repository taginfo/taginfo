#!/bin/sh
#
#  Taginfo source: Potlatch
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

echo "`$DATECMD` Start potlatch..."

DATABASE=$DIR/taginfo-potlatch.db

rm -f $DATABASE

echo "`$DATECMD` Updating resources..."
if [ -d $DIR/resources ]; then
    svn update $DIR/resources
else
    svn checkout http://svn.openstreetmap.org/applications/editors/potlatch2/resources $DIR/resources
fi

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Running import..."
./import_potlatch.rb $DIR

echo "`$DATECMD` Running post.sql..."
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done potlatch."

