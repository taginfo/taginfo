#!/usr/bin/env bash
#------------------------------------------------------------------------------
#
#  Taginfo source: Software
#
#  update.sh DATADIR
#
#------------------------------------------------------------------------------

set -euo pipefail

SRCDIR=$(dirname "$(readlink -f "$0")")
readonly SRCDIR

readonly DATADIR=$1

if [ -z "$DATADIR" ]; then
    echo "Usage: update.sh DATADIR"
    exit 1
fi

readonly ID_TAGGING_SCHEMA_REPO="https://github.com/openstreetmap/id-tagging-schema"
readonly ID_TAGGING_SCHEMA_DIR="$DATADIR/id-tagging-schema"
readonly JOSM_REPO="https://github.com/JOSM/josm"
readonly JOSM_DIR="$DATADIR/josm"

readonly DATABASE=$DATADIR/taginfo-sw.db

# shellcheck source=/dev/null
source "$SRCDIR/../util.sh" sw

# Don't try to read git config which isn't there
export GIT_CONFIG_GLOBAL=/dev/null

process_id_tagging_schema() {
    print_message "Getting iD tagging schema info..."

    if [ -d "$ID_TAGGING_SCHEMA_DIR" ]; then
        (cd "$ID_TAGGING_SCHEMA_DIR"; git pull)
    else
        (cd "$DATADIR"; git clone --depth=1 "$ID_TAGGING_SCHEMA_REPO")
    fi

    run_ruby "$SRCDIR/parse-id-tagging-schema.rb" "$DATADIR"
}

process_josm_code() {
    print_message "Getting JOSM source code..."

    if [ -d "$JOSM_DIR" ]; then
        (cd "$JOSM_DIR"; git pull)
    else
        (cd "$DATADIR"; git clone --depth=1 "$JOSM_REPO")
    fi

    run_ruby "$SRCDIR/parse-josm-code.rb" "$DATADIR"
}

main() {
    print_message "Start software..."

    initialize_database "$DATABASE" "$SRCDIR"
    process_id_tagging_schema
    process_josm_code
    finalize_database "$DATABASE" "$SRCDIR"

    print_message "Done software."
}

main

