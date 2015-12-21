#!/bin/bash
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
readonly SOURCES_DOWNLOAD=$(../bin/taginfo-config.rb sources.download)

# These sources will be created from the actual sources
readonly SOURCES_CREATE=$(../bin/taginfo-config.rb sources.create)

#------------------------------------------------------------------------------

set -e

readonly DIR=$1

if [ -z $DIR ]; then
    echo "Usage: update_all.sh DIR"
    exit 1
fi

readonly TAGINFO_SCRIPT="all"
. ./util.sh

readonly LOGFILE=$(date +%Y%m%dT%H%M)
mkdir -p $DIR/log
exec >$DIR/log/$LOGFILE.log 2>&1


download_source() {
    local source="$1"

    print_message "Downloading $source..."

    mkdir -p $DIR/$source
    run_exe curl --silent --fail --output $DIR/download/taginfo-$source.db.bz2 --time-cond $DIR/download/taginfo-$source.db.bz2 http://taginfo.openstreetmap.org/download/taginfo-$source.db.bz2
    run_exe -l$DIR/$source/taginfo-$source.db bzcat $DIR/download/taginfo-$source.db.bz2

    print_message "Done."
}

download_sources() {
    local sources="$*"

    mkdir -p $DIR/download

    local source
    for source in $sources; do
        download_source $source
    done
}

update_source() {
    local source="$1"

    print_message "Running $source/update.sh..."

    mkdir -p $DIR/$source
    (cd $source && ./update.sh $DIR/$source)

    print_message "Done."
}

update_sources() {
    local sources="$*"

    local source
    for source in $sources; do
        update_source $source
    done
}

update_master() {
    print_message "Running master/update.sh..."

    (cd master && ./update.sh $DIR)

    print_message "Done."
}

compress_file() {
    local filename="$1"
    local compressed="$2"

    print_message "Compressing '$filename' to '$compressed'"
    bzip2 -9 -c $DIR/$filename.db >$DIR/download/taginfo-$compressed.db.bz2 &
}

compress_databases() {
    local sources="$*"

    print_message "Running bzip2 on all databases..."

    local source
    for source in $sources; do
        compress_file $source/taginfo-$source $source
#        bzip2 -9 -c $DIR/$source/taginfo-$source.db >$DIR/download/taginfo-$source.db.bz2 &
    done
    sleep 5 # wait for bzip2 on the smaller dbs to finish

    local db
    for db in master history search; do
        compress_file taginfo-$db $db
#        bzip2 -9 -c $DIR/taginfo-$db.db >$DIR/download/taginfo-$db.db.bz2 &
    done

    wait

    print_message "Done."
}

create_extra_indexes() {
    print_message "Creating extra indexes..."

    run_sql $DIR/db/taginfo-db.db db/add_extra_indexes.sql

    print_message "Done."
}

main() {
    print_message "Start update_all..."

    download_sources $SOURCES_DOWNLOAD
    update_sources $SOURCES_CREATE
    update_master
    compress_databases $SOURCES_CREATE
    create_extra_indexes

    print_message "Done update_all."
}

main


#-- THE END -------------------------------------------------------------------
