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

TAGSTATS=`../../bin/taginfo-config.rb sources.db.tagstats`
if [ "x" = "x$TAGSTATS" ]; then
    TAGSTATS="./tagstats"
fi

if [ ! -f $DIR/interesting_tags.lst ]; then
    echo "File $DIR/interesting_tags.lst missing. Not creating combination statistics."
    echo "  The next taginfo update should automatically correct this."
fi

if [ ! -f $DIR/frequent_tags.lst ]; then
    echo "File $DIR/frequent_tags.lst missing. Not creating maps for tags."
    echo "  The next taginfo update should automatically correct this."
fi

#TAGSTATS="valgrind --leak-check=full --show-reachable=yes $TAGSTATS"
$TAGSTATS --tags $DIR/interesting_tags.lst --map-tags $DIR/frequent_tags.lst --min-tag-combination-count=$min_tag_combination_count --relation-types $DIR/interesting_relation_types.lst --left=$left --bottom=$bottom --top=$top --right=$right --width=$width --height=$height $PLANETFILE $DATABASE

echo "`$DATECMD` Running update_characters... "
./update_characters.rb $DIR

echo "`$DATECMD` Running post.sql... "
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done db."

