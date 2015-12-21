#!/bin/bash
#
#  Taginfo source: DB
#
#  update.sh DIR [PLANETFILE]
#

set -e

# uncomment this if you want to get a core file in case tagstats crashes
#ulimit -c unlimited

readonly DIR=$1
readonly PLANETFILE=${2:-$(../../bin/taginfo-config.rb sources.db.planetfile)}

if [ -z $DIR ]; then
    echo "Usage: update.sh DIR [PLANETFILE]"
    exit 1
fi

readonly DATABASE=$DIR/taginfo-db.db
readonly SELECTION_DB=$DIR/../selection.db
readonly BINDIR=$(../../bin/taginfo-config.rb sources.db.bindir ../../tagstats)
readonly TAGSTATS=$(../../bin/taginfo-config.rb sources.db.tagstats ../../tagstats/tagstats)

readonly TAGINFO_SCRIPT="db"
. ../util.sh

run_tagstats() {
    local top=$(../../bin/taginfo-config.rb geodistribution.top)
    local right=$(../../bin/taginfo-config.rb geodistribution.right)
    local bottom=$(../../bin/taginfo-config.rb geodistribution.bottom)
    local left=$(../../bin/taginfo-config.rb geodistribution.left)
    local width=$(../../bin/taginfo-config.rb geodistribution.width)
    local height=$(../../bin/taginfo-config.rb geodistribution.height)
    local min_tag_combination_count=$(../../bin/taginfo-config.rb sources.master.min_tag_combination_count 1000)

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
#TAGSTATS="valgrind --leak-check=full --show-reachable=yes $TAGSTATS"
    run_exe $TAGSTATS $open_selection_db --min-tag-combination-count=$min_tag_combination_count --left=$left --bottom=$bottom --top=$top --right=$right --width=$width --height=$height $PLANETFILE $DATABASE
}

run_similarity() {
    if [ -e $BINDIR/similarity ]; then
        print_message "Running similarity... "
        run_exe $BINDIR/similarity $DATABASE
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

