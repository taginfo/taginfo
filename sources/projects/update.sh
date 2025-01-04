#!/usr/bin/env bash
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
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

readonly PROJECT_LIST="$DATADIR/taginfo-projects/project_list.txt"
readonly DATABASE="$DATADIR/taginfo-projects.db"
readonly CACHE_PAGES_DB="$DATADIR/projects-cache.db"

# shellcheck source=/dev/null
source "$SRCDIR/../util.sh" projects

initialize_cache() {
    if [ ! -e "$CACHE_PAGES_DB" ]; then
        run_sql "$CACHE_PAGES_DB" "$SRCDIR/cache.sql"
    fi
}

update_projects_list() {
    if [ -d "$DATADIR/taginfo-projects" ]; then
        run_exe git -C "$DATADIR/taginfo-projects" pull --quiet
    else
        run_exe git clone --quiet --depth=1 https://github.com/taginfo/taginfo-projects.git "$DATADIR/taginfo-projects"
    fi
}

update_cache() {
    run_ruby "-l$DATADIR/cache.log" "$SRCDIR/update_cache.rb" "$DATADIR" "$PROJECT_LIST"
}

import_projects_list() {
    run_sql "DIR=$DATADIR" "$DATABASE" "$SRCDIR/get-from-cache.sql"

    run_ruby "-l$DATADIR/parse.log" "$SRCDIR/parse.rb" "$DATADIR"
    run_ruby "-l$DATADIR/get_icons.log" "$SRCDIR/get_icons.rb" "$DATADIR"
}

main() {
    print_message "Start projects..."

    initialize_database "$DATABASE" "$SRCDIR"
    initialize_cache
    update_projects_list
    update_cache
    import_projects_list
    finalize_database "$DATABASE" "$SRCDIR"

    print_message "Done projects."
}

main

