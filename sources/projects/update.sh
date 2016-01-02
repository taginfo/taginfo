#!/bin/bash
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  update.sh DATADIR
#
#------------------------------------------------------------------------------

set -e
set -u

readonly SRCDIR=$(dirname $(readlink -f "$0"))
readonly DATADIR=$1

if [ -z $DATADIR ]; then
    echo "Usage: update.sh DATADIR"
    exit 1
fi

readonly PROJECT_LIST=$DATADIR/taginfo-projects/project_list.txt
readonly DATABASE=$DATADIR/taginfo-projects.db

source $SRCDIR/../util.sh projects

update_projects_list() {
    if [ -d $DATADIR/taginfo-projects ]; then
        run_exe git -C $DATADIR/taginfo-projects pull --quiet
    else
        run_exe git clone --quiet --depth=1 https://github.com/taginfo/taginfo-projects.git $DIR/taginfo-projects
    fi
}

import_projects_list() {
    run_ruby $SRCDIR/import.rb $DATADIR $PROJECT_LIST
    run_ruby $SRCDIR/parse.rb $DATADIR
}

main() {
    print_message "Start projects..."

    initialize_database $DATABASE $SRCDIR
    update_projects_list
    import_projects_list
    finalize_database $DATABASE $SRCDIR

    print_message "Done projects."
}

main

