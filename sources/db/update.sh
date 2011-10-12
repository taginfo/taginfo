#!/bin/sh
#
#  Taginfo source: DB
#
#  update.sh DIR [PLANETFILE]
#

set -e

# uncomment this if you want to get a core file in case tagstats crashes
#ulimit -c 1000000000

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
rm -f $DIR/count.db

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Running count... "

top=`../../bin/taginfo-config.rb geodistribution.top`
right=`../../bin/taginfo-config.rb geodistribution.right`
bottom=`../../bin/taginfo-config.rb geodistribution.bottom`
left=`../../bin/taginfo-config.rb geodistribution.left`
width=`../../bin/taginfo-config.rb geodistribution.width`
height=`../../bin/taginfo-config.rb geodistribution.height`

HERE=`pwd`
cd $DIR
#valgrind --leak-check=full --show-reachable=yes $HERE/tagstats $PLANETFILE >valgrind.log 2>&1
$HERE/tagstats --left=$left --bottom=$bottom --top=$top --right=$right --width=$width --height=$height $PLANETFILE
cd $HERE

echo "`$DATECMD` Running update_characters... "
./update_characters.pl $DIR

echo "`$DATECMD` Running post.sql... "
perl -pe "s|__DIR__|$DIR|" post.sql | sqlite3 $DATABASE

echo "`$DATECMD` Done db."

