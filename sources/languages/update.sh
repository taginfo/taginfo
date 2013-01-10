#!/bin/sh
#
#  Taginfo source: Languages
#
#  update.sh DIR
#

set -e

DIR=$1
REGISTRY_URL="http://www.iana.org/assignments/language-subtag-registry"
REGISTRY_FILE="$DIR/language-subtag-registry"

DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo "`$DATECMD` Start languages..."

DATABASE=$DIR/taginfo-languages.db

rm -f $DATABASE

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Getting subtag registry..."
curl --silent --time-cond $REGISTRY_FILE --output $REGISTRY_FILE $REGISTRY_URL

echo "`$DATECMD` Running import..."
./import_subtag_registry.rb $DIR

echo "`$DATECMD` Running post.sql..."
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done languages."

