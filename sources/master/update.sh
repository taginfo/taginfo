#!/bin/bash
#
#  Taginfo Master DB
#
#  update.sh DIR
#

set -e

readonly DIR=$1

if [ -z $DIR ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

readonly MASTER_DB=$DIR/taginfo-master.db
readonly HISTORY_DB=$DIR/taginfo-history.db
readonly SELECTION_DB=$DIR/selection.db

readonly TAGINFO_SCRIPT="master"
. ../util.sh

create_search_database() {
    local tokenizer=$(../../bin/taginfo-config.rb sources.master.tokenizer simple)
    rm -f $DIR/taginfo-search.db
    run_sql DIR=$DIR TOKENIZER=$tokenizer $DIR/taginfo-search.db search.sql
}

create_master_database() {
    rm -f $MASTER_DB
    run_sql $MASTER_DB languages.sql
    run_sql DIR=$DIR $MASTER_DB master.sql
}

create_selection_database() {
    local min_count_tags=$(../../bin/taginfo-config.rb sources.master.min_count_tags 10000)
    local min_count_for_map=$(../../bin/taginfo-config.rb sources.master.min_count_for_map 1000)
    local min_count_relations_per_type=$(../../bin/taginfo-config.rb sources.master.min_count_relations_per_type 100)

    rm -f $SELECTION_DB
    run_sql \
        DIR=$DIR \
        MIN_COUNT_FOR_MAP=$min_count_for_map \
        MIN_COUNT_TAGS=$min_count_tags \
        MIN_COUNT_RELATIONS_PER_TYPE=$min_count_relations_per_type \
        $SELECTION_DB selection.sql

    run_sql $SELECTION_DB ../db/show_selection_stats.sql "Selection database contents:"
}

update_history_database() {
    if [ ! -e $HISTORY_DB ]; then
        print_message "No history database from previous runs. Initializing a new one..."
        run_sql $HISTORY_DB history_init.sql
    fi

    run_sql DIR=$DIR $HISTORY_DB history_update.sql
}

main() {
    print_message "Start master..."

    create_search_database
    create_master_database
    create_selection_database
    update_history_database

    print_message "Done master."
}

main

