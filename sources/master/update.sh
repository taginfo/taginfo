#!/bin/sh
#
#  Taginfo Master DB
#
#  update.sh DIR
#

set -e

DIR=$1

[ -n "$M4" ] || M4=m4
DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo "`$DATECMD` Start master..."

MASTER_DB=$DIR/taginfo-master.db
HISTORY_DB=$DIR/taginfo-history.db
SELECTION_DB=$DIR/selection.db

echo "`$DATECMD` Create search database..."

rm -f $DIR/taginfo-search.db
$M4 --prefix-builtins -D __DIR__=$DIR search.sql | sqlite3 $DIR/taginfo-search.db

echo "`$DATECMD` Create master database..."

rm -f $MASTER_DB
sqlite3 $MASTER_DB <languages.sql
$M4 --prefix-builtins -D __DIR__=$DIR master.sql | sqlite3 $MASTER_DB

echo "`$DATECMD` Create selection database..."

min_count_tags=`../../bin/taginfo-config.rb sources.master.min_count_tags 10000`
min_count_for_map=`../../bin/taginfo-config.rb sources.master.min_count_for_map 1000`
min_count_relations_per_type=`../../bin/taginfo-config.rb sources.master.min_count_relations_per_type 100`

rm -f $SELECTION_DB
$M4 --prefix-builtins \
   -D __DIR__=$DIR \
   -D __MIN_COUNT_FOR_MAP__=$min_count_for_map \
   -D __MIN_COUNT_TAGS__=$min_count_tags \
   -D __MIN_COUNT_RELATIONS_PER_TYPE__=$min_count_relations_per_type \
   selection.sql | sqlite3 $SELECTION_DB

echo "Selection database contents:"
sqlite3 $SELECTION_DB < ../db/show_selection_stats.sql

echo "`$DATECMD` Update history database..."

if [ ! -e $HISTORY_DB ]; then
    sqlite3 $HISTORY_DB < history_init.sql
fi

$M4 --prefix-builtins -D __DIR__=$DIR history_update.sql | sqlite3 $HISTORY_DB

echo "`$DATECMD` Done master."

