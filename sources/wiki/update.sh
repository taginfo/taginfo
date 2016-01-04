#!/bin/bash
#------------------------------------------------------------------------------
#
#  Taginfo source: Wiki
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

readonly DATABASE=$DATADIR/taginfo-wiki.db
readonly CACHEDB=$DATADIR/wikicache.db
readonly LOGFILE_WIKI_DATA=$DATADIR/get_wiki_data.log
readonly LOGFILE_IMAGE_INFO=$DATADIR/get_image_info.log

source $SRCDIR/../util.sh wiki

initialize_cache() {
    if [ ! -e $CACHEDB ]; then
        run_sql $CACHEDB $SRCDIR/cache.sql
    fi
}

get_page_list() {
    print_message "Getting page list..."
    rm -f $DATADIR/all_wiki_pages.list
    rm -f $DATADIR/interesting_wiki_pages.list
    run_ruby $SRCDIR/get_page_list.rb $DATADIR
}

get_wiki_data() {
    print_message "Getting wiki data..."
    run_ruby -l$LOGFILE_WIKI_DATA $SRCDIR/get_wiki_data.rb $DATADIR

    print_message "Getting image info..."
    run_ruby -l$LOGFILE_IMAGE_INFO $SRCDIR/get_image_info.rb $DATADIR
}

get_links() {
    print_message "Getting links to Key/Tag/Relation pages..."
    run_ruby -l$DATADIR/links.list $SRCDIR/get_links.rb $DATADIR

    print_message "Classifying links..."
    run_ruby $SRCDIR/classify_links.rb $DATADIR
}

extract_words() {
    print_message "Extracting words..."
    run_ruby $SRCDIR/extract_words.rb $DATADIR
}

main() {
    print_message "Start wiki..."

    initialize_database $DATABASE $SRCDIR
    initialize_cache
    get_page_list
    get_wiki_data
    #get_links
    extract_words
    finalize_database $DATABASE $SRCDIR

    print_message "Done wiki."
}

main

