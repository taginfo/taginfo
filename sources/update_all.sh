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

# These sources will be downloaded from http://taginfo.openstreetmap.org/download/
# Note that this will NOT work for the "db" source! Well, you can download it,
# but it will fail later, because the database is changed by the master.sql
# scripts.
SOURCES_DOWNLOAD=`../bin/taginfo-config.rb sources.download`

# These sources will be created from the actual sources
SOURCES_CREATE=`../bin/taginfo-config.rb sources.create`

#------------------------------------------------------------------------------

set -e

DATECMD='date +%Y-%m-%dT%H:%M:%S'

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update_all.sh DIR"
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
    curl --silent --fail --output $DIR/download/taginfo-$source.db.bz2 http://taginfo.openstreetmap.org/download/taginfo-$source.db.bz2
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

echo "====================================="
echo "`$DATECMD` Running bzip2 on all databases..."
for source in $SOURCES_CREATE; do
    bzip2 -9 -c $DIR/$source/taginfo-$source.db >$DIR/download/taginfo-$source.db.bz2 &
done
sleep 5 # wait for bzip2 on the smaller dbs to finish
bzip2 -9 -c $DIR/taginfo-master.db >$DIR/download/taginfo-master.db.bz2 &
bzip2 -9 -c $DIR/taginfo-search.db >$DIR/download/taginfo-search.db.bz2 &

wait
echo "Done."

echo "====================================="
echo "`$DATECMD` Done update_all."


#-- THE END -------------------------------------------------------------------
