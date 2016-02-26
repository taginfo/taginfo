#!/usr/bin/env bash
#------------------------------------------------------------------------------
#
#  Taginfo source: DB
#
#  update.sh DATADIR [OSM_FILE]
#
#------------------------------------------------------------------------------

set -e
set -u

# uncomment this if you want to get a core file in case tagstats crashes
#ulimit -c unlimited

readonly SRCDIR=$(dirname $(readlink -f "$0"))
readonly DATADIR=$1

if [ -z $DATADIR ]; then
    echo "Usage: update.sh DATADIR [OSM_FILE]"
    exit 1
fi

readonly DATABASE=$DATADIR/taginfo-db.db
readonly SELECTION_DB=$DATADIR/../selection.db

source $SRCDIR/../util.sh db

readonly OSM_FILE=${2:-$(get_config sources.db.planetfile)}

run_tagstats() {
    local top=$(get_config geodistribution.top)
    local right=$(get_config geodistribution.right)
    local bottom=$(get_config geodistribution.bottom)
    local left=$(get_config geodistribution.left)
    local width=$(get_config geodistribution.width)
    local height=$(get_config geodistribution.height)
    local min_tag_combination_count=$(get_config sources.master.min_tag_combination_count 1000)
    local index=$(get_config tagstats.geodistribution)
    local tagstats=$(get_bindir)/tagstats

    local open_selection_db=""
    if [[ -f $SELECTION_DB && -s $SELECTION_DB ]]; then
        open_selection_db="--selection-db=$SELECTION_DB"
        print_message "Reading selection database '$SELECTION_DB'"
        run_sql $SELECTION_DB $SRCDIR/show_selection_stats.sql "Selection database contents:"
    else
        print_message "Selection database '$SELECTION_DB' not found. Not creating some statistics."
        print_message "  The next taginfo update should automatically correct this."
    fi

    print_message "Running tagstats... "
#tagstats="valgrind --leak-check=full --show-reachable=yes $tagstats"
    run_exe $tagstats $open_selection_db --index=$index --min-tag-combination-count=$min_tag_combination_count --left=$left --bottom=$bottom --top=$top --right=$right --width=$width --height=$height $OSM_FILE $DATABASE
}

run_similarity() {
    local similarity=$(get_bindir)/similarity
    if [ -e $similarity ]; then
        print_message "Running similarity... "
        run_exe $similarity $DATABASE
    else
        print_message "WARNING: Not running 'similarity', because binary not found. Please compile it."
    fi

    run_sql $DATABASE $SRCDIR/post_similar_keys.sql
}

update_characters() {
    print_message "Running update_characters... "
    run_ruby $SRCDIR/update_characters.rb $DATADIR
}

main() {
    print_message "Start db..."

    rm -f $DATABASE
    initialize_database $DATABASE $SRCDIR
    run_tagstats
    run_similarity
    update_characters

#print_message "Running taginfo_unicode... "
#./taginfo_unicode $DATABASE

    run_sql $DATABASE $SRCDIR/post_grades.sql
    run_sql $DATABASE $SRCDIR/post_indexes.sql
    finalize_database $DATABASE $SRCDIR

    print_message "Done db."
}

main

