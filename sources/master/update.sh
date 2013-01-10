#!/bin/sh
#
#  Taginfo Master DB
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

echo "`$DATECMD` Create search database..."

rm -f $DIR/taginfo-search.db
perl -pe "s|__DIR__|$DIR|" search.sql | sqlite3 $DIR/taginfo-search.db

echo "`$DATECMD` Start master..."

DATABASE=$DIR/taginfo-master.db

rm -f $DATABASE

sqlite3 $DATABASE <languages.sql
perl -pe "s|__DIR__|$DIR|" master.sql | sqlite3 $DATABASE
perl -pe "s|__DIR__|$DIR|" interesting_tags.sql | sqlite3 $DATABASE
perl -pe "s|__DIR__|$DIR|" interesting_relation_types.sql | sqlite3 $DATABASE

echo "`$DATECMD` Done master."

