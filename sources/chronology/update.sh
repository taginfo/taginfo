#!/usr/bin/env bash
#------------------------------------------------------------------------------
#
#  Taginfo source: Chronology
#
#  update.sh DATADIR [OSM_HISTORY_FILE]
#
#------------------------------------------------------------------------------

set -euo pipefail

readonly SRCDIR=$(dirname $(readlink -f "$0"))
readonly DATADIR=$1

if [ -z $DATADIR ]; then
    echo "Usage: update.sh DATADIR [OSM_HISTORY_FILE]"
    exit 1
fi

readonly DATABASE=$DATADIR/taginfo-chronology.db
readonly SELECTION_DB=$DATADIR/../selection.db

source $SRCDIR/../util.sh chronology

readonly OSM_HISTORY_FILE=${2:-$(get_config sources.chronology.osm_history_file)}

run_chronology() {
    local cmd=$(get_bindir)/taginfo-chronology

    local open_selection_db=""
    if [[ -f $SELECTION_DB && -s $SELECTION_DB ]]; then
        open_selection_db="--selection-db=$SELECTION_DB"
        print_message "Reading selection database '$SELECTION_DB'"
    else
        print_message "Selection database '$SELECTION_DB' not found. Not creating some statistics."
        print_message "  The next taginfo update should automatically correct this."
    fi

    print_message "Running taginfo-chronology... "
    run_exe $cmd $open_selection_db $OSM_HISTORY_FILE $DATABASE
}

main() {
    print_message "Start chronology..."

    rm -f $DATABASE
    initialize_database $DATABASE $SRCDIR
    run_chronology
    finalize_database $DATABASE $SRCDIR

    print_message "Done chronology."
}

main

