#!/bin/sh
#------------------------------------------------------------------------------
#
#  Taginfo
#
#  update_all.sh DIR
#
#  Call this to update your Taginfo databases. All data will be store in the
#  directory DIR. Create an empty directory before starting for the first time!
#
#  In this directory you will find:
#  log      - directory with log files from running the update script
#  download - directory with bzipped databases for download
#  ...      - a directory for each source with database and possible some
#             temporary files
#
#------------------------------------------------------------------------------

# these sources will be downloaded from http://taginfo.openstreetmap.de/download/
SOURCES_DOWNLOAD=""

# these sources will be created from the actual sources
SOURCES_CREATE="josm potlatch merkaartor wiki db"

#------------------------------------------------------------------------------

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

for source in $SOURCES_DOWNLOAD; do
    echo "====================================="
    echo "Downloading $source..."
    mkdir -p $DIR/$source
    wget --quiet -O $DIR/download/taginfo-$source.db.bz2 http://taginfo.openstreetmap.de/download/taginfo-$source.db.bz2
    bzcat $DIR/download/taginfo-$source.db.bz2 >$DIR/$source/taginfo-$source.db
    echo "Done."
done

for source in $SOURCES_CREATE; do
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

for source in $SOURCES_CREATE; do
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


#-- THE END -------------------------------------------------------------------
