#!/bin/bash
#
#  Taginfo source: Wiki
#
#  update.sh DIR
#

set -e

readonly DIR=$1

if [ -z $DIR ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

readonly DATABASE=$DIR/taginfo-wiki.db
readonly CACHEDB=$DIR/wikicache.db
readonly LOGFILE_WIKI_DATA=$DIR/get_wiki_data.log
readonly LOGFILE_IMAGE_INFO=$DIR/get_image_info.log

readonly TAGINFO_SCRIPT="wiki"
. ../util.sh

initialize_cache() {
    if [ ! -e $CACHEDB ]; then
        run_sql $CACHEDB cache.sql
    fi
}

get_page_list() {
    print_message "Getting page list..."
    rm -f $DIR/allpages.list
    rm -f $DIR/tagpages.list
    run_ruby ./get_page_list.rb $DIR
}

get_wiki_data() {
    print_message "Getting wiki data..."
    run_ruby -l$LOGFILE_WIKI_DATA ./get_wiki_data.rb $DIR

    print_message "Getting image info..."
    run_ruby -l$LOGFILE_IMAGE_INFO ./get_image_info.rb $DIR
}

get_links() {
    print_message "Getting links to Key/Tag/Relation pages..."
    run_ruby -l$DIR/links.list ./get_links.rb $DIR

    print_message "Classifying links..."
    run_ruby ./classify_links.rb $DIR
}

extract_words() {
    print_message "Extracting words..."
    run_ruby ./extract_words.rb $DIR
}

main() {
    print_message "Start wiki..."

    initialize_database
    initialize_cache
    get_page_list
    get_wiki_data
    #get_links
    extract_words
    finalize_database

    print_message "Done wiki."
}

main

