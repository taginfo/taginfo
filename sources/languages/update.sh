#!/bin/bash
#
#  Taginfo source: Languages
#
#  update.sh DIR
#

set -e

readonly DIR=$1

if [ -z $DIR ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

readonly REGISTRY_URL="http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry"
readonly REGISTRY_FILE="$DIR/language-subtag-registry"
readonly CLDR_URL="http://unicode.org/Public/cldr/latest/core.zip"
readonly CLDR_FILE="$DIR/cldr-core.zip"
readonly CLDR_DIR="$DIR/cldr"
readonly UNICODE_SCRIPTS_URL="http://www.unicode.org/Public/UNIDATA/Scripts.txt"
readonly UNICODE_SCRIPTS_FILE="$DIR/Scripts.txt"
readonly PROPERTY_ALIASES_URL="http://www.unicode.org/Public/UNIDATA/PropertyValueAliases.txt"
readonly PROPERTY_ALIASES_FILE="$DIR/PropertyValueAliases.txt"
readonly DATABASE=$DIR/taginfo-languages.db

readonly TAGINFO_SCRIPT="languages"
. ../util.sh

update_file() {
    local file="$1"
    local url="$2"

    if run_exe curl --silent --fail --location --time-cond $file --output $file $url; then
        return 0
    else
        error=$?
        if [ "$error" = "22" ]; then
            print_message "WARNING: Getting ${url} failed. Using old version."
        else
            print_message "ERROR: Could not get ${url}: curl error: $error"
            exit 1
        fi
    fi
}

getting_subtag_registry() {
    print_message "Getting subtag registry..."
    update_file $REGISTRY_FILE $REGISTRY_URL

    print_message "Running subtag import..."
    run_ruby ./import_subtag_registry.rb $DIR
}

getting_cldr() {
    print_message "Getting CLDR..."
    update_file $CLDR_FILE $CLDR_URL

    print_message "Unpacking CLDR..."
    rm -fr $CLDR_DIR
    mkdir $CLDR_DIR
    run_exe unzip -q -d $CLDR_DIR $CLDR_FILE
}

getting_unicode_scripts() {
    print_message "Getting unicode scripts..."
    update_file $UNICODE_SCRIPTS_FILE $UNICODE_SCRIPTS_URL
    update_file $PROPERTY_ALIASES_FILE $PROPERTY_ALIASES_URL

    print_message "Running unicode scripts import..."
    run_ruby ./import_unicode_scripts.rb $DIR
}

main() {
    print_message "Start languages..."

    initialize_database
    getting_subtag_registry
    getting_cldr
    getting_unicode_scripts
    finalize_database

    print_message "Done languages."
}

main

