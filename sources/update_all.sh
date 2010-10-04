#!/bin/sh
#
#  Taginfo
#
#  update_all.sh DIR
#

SOURCES="db josm wiki"

set -e

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

exec >$DIR/update_all.log 2>&1

echo -n "Start: "; date

mkdir -p $DIR/download

for source in $SOURCES; do
    echo "====================================="
    echo "Running $source/update.sh..."
    mkdir -p $DIR/$source
    cd $source
    ./update.sh $DIR/$source
    cd ..
    echo "Running bzip2..."
    bzip2 -9 -c $DIR/$source/taginfo-$source.db >$DIR/download/taginfo-$source.db.bz2
    echo "Done."
done

echo "====================================="
echo "Running master/update.sh..."
cd master
./update.sh $DIR
cd ..
echo "Running bzip2..."
bzip2 -9 -c $DIR/taginfo-master.db >$DIR/download/taginfo-master.db.bz2
echo "Done."

echo -n "Done: "; date

