#!/bin/sh
#
#  Taginfo
#
#  update_all.sh DIR
#

SOURCES="josm potlatch merkaartor wiki db"

set -e

DATECMD='date +%Y-%m-%dT%H:%M:%S'

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

LOGFILE=`date +%Y%m%dT%H%M`
mkdir -p $DIR/log
exec >$DIR/log/$LOGFILE.log 2>&1

echo "`$DATECMD` Start update_all..."

mkdir -p $DIR/download

for source in $SOURCES; do
    echo "====================================="
    echo "Running $source/update.sh..."
    mkdir -p $DIR/$source
    cd $source
    ./update.sh $DIR/$source
    cd ..
    echo "Done."
done

echo "====================================="
echo "Running master/update.sh..."
cd master
./update.sh $DIR
cd ..

for source in $SOURCES; do
    echo "====================================="
    echo "Running bzip2 on $source..."
    bzip2 -9 -c $DIR/$source/taginfo-$source.db >$DIR/download/taginfo-$source.db.bz2
    echo "Done."
done

echo "Running bzip2..."
bzip2 -9 -c $DIR/taginfo-master.db >$DIR/download/taginfo-master.db.bz2
echo "Done."

echo "====================================="
echo "`$DATECMD` Done update_all."

