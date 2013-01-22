#!/bin/sh
#
#  Taginfo source: Merkaartor
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

echo "`$DATECMD` Start merkaartor..."

EXEC_RUBY="$TAGINFO_RUBY"
if [ "x$EXEC_RUBY" = "x" ]; then
    EXEC_RUBY=ruby
fi
echo "Running with ruby set as '${EXEC_RUBY}'"

DATABASE=$DIR/taginfo-merkaartor.db

rm -f $DATABASE

echo "`$DATECMD` Updating resources..."
if [ -d $DIR/git-source ]; then
    cd $DIR/git-source
    git pull
    cd -
else
    git clone http://git.gitorious.org/merkaartor/main.git $DIR/git-source
fi

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Running import..."
$EXEC_RUBY ./import_merkaartor.rb $DIR

echo "`$DATECMD` Running post.sql..."
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done merkaartor."

