#!/usr/bin/env bash
#------------------------------------------------------------------------------
#
#  Taginfo
#
#  update_all.sh DATADIR
#
#  Call this to update your Taginfo databases. All data will be store in the
#  directory DATADIR. Create an empty directory before starting for the first time!
#
#  In this directory you will find:
#  log      - directory with log files from running the update script
#  download - directory with bzipped databases for download
#  ...      - a directory for each source with database and possible some
#             temporary files
#
#------------------------------------------------------------------------------

set -euo pipefail

readonly SRCDIR=$(dirname $(readlink -f "$0"))
readonly DATADIR=$1

if [ -z $DATADIR ]; then
    echo "Usage: update_all.sh DATADIR"
    exit 1
fi

source $SRCDIR/util.sh all

readonly LOGFILE=$(date +%Y%m%dT%H%M)
mkdir -p $DATADIR/log
exec >$DATADIR/log/$LOGFILE.log 2>&1

if which pbzip2 >/dev/null; then
    BZIP_COMMAND=pbzip2
else
    BZIP_COMMAND=bzip2
fi

download_source() {
    local source="$1"

    print_message "Downloading and uncompressing $source..."

    mkdir -p $DATADIR/$source
    run_exe curl --silent --fail --output $DATADIR/download/taginfo-$source.db.bz2 --time-cond $DATADIR/download/taginfo-$source.db.bz2 https://taginfo.openstreetmap.org/download/taginfo-$source.db.bz2
    run_exe -l$DATADIR/$source/taginfo-$source.db $BZIP_COMMAND -d -c $DATADIR/download/taginfo-$source.db.bz2

    print_message "Done."
}

download_sources() {
    local sources="$*"

    mkdir -p $DATADIR/download

    local source
    for source in $sources; do
        download_source $source
    done
}

update_source() {
    local source="$1"

    print_message "Running $source/update.sh..."

    mkdir -p $DATADIR/$source
    $SRCDIR/$source/update.sh $DATADIR/$source

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

    $SRCDIR/master/update.sh $DATADIR

    print_message "Done."
}

compress_file() {
    local filename="$1"
    local compressed="$2"

    print_message "Compressing '$filename' to '$compressed' using '$BZIP_COMMAND'"
    $BZIP_COMMAND -9 -c $DATADIR/$filename.db >$DATADIR/download/taginfo-$compressed.db.bz2 &
}

compress_source_databases() {
    local sources="$*"

    print_message "Compressing all source databases..."

    local source
    for source in $sources; do
        compress_file $source/taginfo-$source $source
    done

    wait

    print_message "Done."
}

compress_extra_databases() {
    local sources="$*"

    print_message "Compressing all extra databases..."

    compress_file taginfo-master master
    compress_file taginfo-history history

    wait

    print_message "Done."
}

create_extra_indexes() {
    print_message "Creating extra indexes..."

    run_sql $DATADIR/db/taginfo-db.db $SRCDIR/db/add_extra_indexes.sql
    run_sql $DATADIR/db/taginfo-db.db $SRCDIR/db/add_ftsearch.sql

    print_message "Done."
}

main() {
    print_message "Start update_all..."

    # These sources will be downloaded from https://taginfo.openstreetmap.org/download/
    # Note that this will NOT work for the "db" source! Well, you can download it,
    # but it will fail later, because the database is changed by the master.sql
    # scripts.
    local sources_download=$(get_config sources.download)

    # These sources will be created from the actual sources
    local sources_create=$(get_config sources.create)

    download_sources $sources_download
    update_sources $sources_create
    compress_source_databases $sources_create
    create_extra_indexes
    update_master
    compress_extra_databases $sources_create

    print_message "Done update_all."
}

main


#-- THE END -------------------------------------------------------------------
