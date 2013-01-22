#!/bin/sh
#
#  Taginfo source: JOSM
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

echo "`$DATECMD` Start josm..."

EXEC_RUBY="$TAGINFO_RUBY"
if [ "x$EXEC_RUBY" = "x" ]; then
    EXEC_RUBY=ruby
fi
echo "Running with ruby set as '${EXEC_RUBY}'"

DATABASE=$DIR/taginfo-josm.db
ELEMSTYLES=$DIR/elemstyles.xml

rm -f $DATABASE
rm -f $ELEMSTYLES

echo "`$DATECMD` Getting styles..."
curl --silent --output $ELEMSTYLES http://josm.openstreetmap.de/svn/trunk/styles/standard/elemstyles.xml

echo "`$DATECMD` Updating images..."
if [ -d $DIR/svn-source ]; then
    cd $DIR/svn-source
    svn update
    cd -
else
    svn checkout http://josm.openstreetmap.de/svn/trunk/images/styles $DIR/svn-source
fi

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Running import..."
$EXEC_RUBY ./import_josm.rb $DIR

echo "`$DATECMD` Running post.sql..."
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done josm."

