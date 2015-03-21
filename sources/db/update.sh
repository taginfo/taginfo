#!/bin/sh
#
#  Taginfo source: DB
#
#  update.sh DIR [PLANETFILE]
#

set -e

# uncomment this if you want to get a core file in case tagstats crashes
#ulimit -c unlimited

DIR=$1
PLANETFILE=$2

DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR [PLANETFILE]"
    exit 1
fi

if [ "x" = "x$PLANETFILE" ]; then
    PLANETFILE=`../../bin/taginfo-config.rb sources.db.planetfile`
fi

echo "`$DATECMD` Start db..."

DATABASE=$DIR/taginfo-db.db
SELECTION_DB=$DIR/../selection.db

rm -f $DATABASE

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Running tagstats... "
top=`../../bin/taginfo-config.rb geodistribution.top`
right=`../../bin/taginfo-config.rb geodistribution.right`
bottom=`../../bin/taginfo-config.rb geodistribution.bottom`
left=`../../bin/taginfo-config.rb geodistribution.left`
width=`../../bin/taginfo-config.rb geodistribution.width`
height=`../../bin/taginfo-config.rb geodistribution.height`
min_tag_combination_count=`../../bin/taginfo-config.rb sources.master.min_tag_combination_count 1000`

BINDIR=`../../bin/taginfo-config.rb sources.db.bindir ../../tagstats`
TAGSTATS=`../../bin/taginfo-config.rb sources.db.tagstats ../../tagstats/tagstats`

if [ -f $SELECTION_DB ]; then
    OPEN_SELECTION_DB="--selection-db=$SELECTION_DB"
    echo "Reading selection database '$SELECTION_DB'"
    echo "Selection database contents:"
    sqlite3 $SELECTION_DB < show_selection_stats.sql
else
    OPEN_SELECTION_DB=""
    echo "Selection database '$SELECTION_DB' not found. Not creating some statistics."
    echo "  The next taginfo update should automatically correct this."
fi

#TAGSTATS="valgrind --leak-check=full --show-reachable=yes $TAGSTATS"
$TAGSTATS $OPEN_SELECTION_DB --min-tag-combination-count=$min_tag_combination_count --left=$left --bottom=$bottom --top=$top --right=$right --width=$width --height=$height $PLANETFILE $DATABASE

if [ -e $BINDIR/similarity ]; then
    echo "`$DATECMD` Running similarity... "
    $BINDIR/similarity $DATABASE
else
    echo "WARNING: Not running 'similarity', because binary not found. Please compile it."
fi

echo "`$DATECMD` Running post_similar_keys.sql... "
sqlite3 $DATABASE <post_similar_keys.sql

echo "`$DATECMD` Running update_characters... "
./update_characters.rb $DIR

echo "`$DATECMD` Running post_grades.sql... "
sqlite3 $DATABASE <post_grades.sql

echo "`$DATECMD` Running post_indexes.sql... "
sqlite3 $DATABASE <post_indexes.sql

echo "`$DATECMD` Running post.sql... "
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done db."

