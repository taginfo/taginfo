#!/bin/bash
#
#  Taginfo source: DB
#
#  update.sh DIR [OSM_FILE]
#

set -e

# uncomment this if you want to get a core file in case tagstats crashes
#ulimit -c unlimited

readonly DIR=$1

if [ -z $DIR ]; then
    echo "Usage: update.sh DIR [OSM_FILE]"
    exit 1
fi

readonly DATABASE=$DIR/taginfo-db.db
readonly SELECTION_DB=$DIR/../selection.db

readonly TAGINFO_SCRIPT="db"
. ../util.sh

readonly OSM_FILE=${2:-$(get_config sources.db.planetfile)}

run_tagstats() {
    local top=$(get_config geodistribution.top)
    local right=$(get_config geodistribution.right)
    local bottom=$(get_config geodistribution.bottom)
    local left=$(get_config geodistribution.left)
    local width=$(get_config geodistribution.width)
    local height=$(get_config geodistribution.height)
    local min_tag_combination_count=$(get_config sources.master.min_tag_combination_count 1000)
    local tagstats=$(get_config sources.db.bindir ../../tagstats)/tagstats

    local open_selection_db=""
    if [[ -f $SELECTION_DB && -s $SELECTION_DB ]]; then
        open_selection_db="--selection-db=$SELECTION_DB"
        print_message "Reading selection database '$SELECTION_DB'"
        run_sql $SELECTION_DB show_selection_stats.sql "Selection database contents:"
    else
        print_message "Selection database '$SELECTION_DB' not found. Not creating some statistics."
        print_message "  The next taginfo update should automatically correct this."
    fi

    print_message "Running tagstats... "
#tagstats="valgrind --leak-check=full --show-reachable=yes $tagstats"
    run_exe $tagstats $open_selection_db --min-tag-combination-count=$min_tag_combination_count --left=$left --bottom=$bottom --top=$top --right=$right --width=$width --height=$height $OSM_FILE $DATABASE
}

run_similarity() {
    local similarity=$(get_config sources.db.bindir ../../tagstats)/similarity
    if [ -e $similarity ]; then
        print_message "Running similarity... "
        run_exe $similarity $DATABASE
    else
        print_message "WARNING: Not running 'similarity', because binary not found. Please compile it."
    fi

    run_sql $DATABASE post_similar_keys.sql
}

update_characters() {
    print_message "Running update_characters... "
    run_ruby ./update_characters.rb $DIR
}

main() {
    print_message "Start db..."

    rm -f $DATABASE
    initialize_database
    run_tagstats
    run_similarity
    update_characters

#print_message "Running taginfo_unicode... "
#./taginfo_unicode $DATABASE

    run_sql $DATABASE post_grades.sql
    run_sql $DATABASE post_indexes.sql
    finalize_database

    print_message "Done db."
}

main

