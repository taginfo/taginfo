#!/bin/sh
#
#  Taginfo source: Wiki
#
#  update.sh DIR
#

set -e

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo -n "Start wiki: "; date

DATABASE=$DIR/taginfo-wiki.db
LOGFILE=$DIR/get_wiki_data.log

rm -f $DIR/allpages.list
rm -f $DIR/tagpages.list
rm -f $LOGFILE
rm -f $DATABASE

echo "Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "Getting page list..."
./get_page_list.rb $DIR

echo "Getting wiki data..."
./get_wiki_data.rb $DIR >$LOGFILE

echo "Running post.sql..."
sqlite3 $DATABASE <post.sql

echo -n "Done wiki: "; date

