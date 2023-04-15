#!/usr/bin/env bash
#------------------------------------------------------------------------------
#
#  Taginfo source: Wikidata
#
#  update.sh DATADIR
#
#------------------------------------------------------------------------------

set -euo pipefail

readonly SRCDIR=$(dirname "$(readlink -f "$0")")
readonly DATADIR=$1

if [ -z "$DATADIR" ]; then
    echo "Usage: update.sh DATADIR"
    exit 1
fi

readonly DATABASE="$DATADIR/taginfo-wikidata.db"

# shellcheck source=/dev/null
source "$SRCDIR/../util.sh" wikidata

import() {
    run_ruby "-l$DATADIR/import.log" "$SRCDIR/import.rb" "$DATADIR"
}

main() {
    print_message "Start wikidata..."

    initialize_database "$DATABASE" "$SRCDIR"
    import
    finalize_database "$DATABASE" "$SRCDIR"

    print_message "Done wikidata."
}

main

