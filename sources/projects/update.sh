#!/bin/bash
#
#  Taginfo source: Projects
#
#  update.sh DIR
#

set -e

readonly DIR=$1

if [ -z $DIR ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

readonly PROJECT_LIST=$DIR/taginfo-projects/project_list.txt
readonly DATABASE=$DIR/taginfo-projects.db

readonly TAGINFO_SCRIPT="projects"
. ../util.sh

update_projects_list() {
    if [ -d $DIR/taginfo-projects ]; then
        (cd $DIR/taginfo-projects && run_exe git pull --quiet)
    else
        run_exe git clone --quiet --depth=1 https://github.com/taginfo/taginfo-projects.git $DIR/taginfo-projects
    fi
}

import_projects_list() {
    run_ruby ./import.rb $DIR $PROJECT_LIST
    run_ruby ./parse.rb $DIR
}

main() {
    print_message "Start projects..."

    initialize_database
    update_projects_list
    import_projects_list
    finalize_database

    print_message "Done projects."
}

main

