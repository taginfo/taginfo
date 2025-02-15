#!/usr/bin/env bash
#------------------------------------------------------------------------------
#
#  Taginfo source: Languages
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

readonly REGISTRY_URL="https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry"
readonly REGISTRY_FILE="$DATADIR/language-subtag-registry"
readonly CLDR_URL="https://unicode.org/Public/cldr/latest/core.zip"
readonly CLDR_FILE="$DATADIR/cldr-core.zip"
readonly CLDR_DIR="$DATADIR/cldr"
readonly UNICODE_DATA_URL="https://www.unicode.org/Public/UNIDATA/UnicodeData.txt"
readonly UNICODE_DATA_FILE="$DATADIR/UnicodeData.txt"
readonly UNICODE_SCRIPTS_URL="https://www.unicode.org/Public/UNIDATA/Scripts.txt"
readonly UNICODE_SCRIPTS_FILE="$DATADIR/Scripts.txt"
readonly PROPERTY_ALIASES_URL="https://www.unicode.org/Public/UNIDATA/PropertyValueAliases.txt"
readonly PROPERTY_ALIASES_FILE="$DATADIR/PropertyValueAliases.txt"
readonly WIKIMEDIAS_URL="https://wikistats.wmcloud.org/wikimedias_csv.php"
readonly WIKIMEDIAS_FILE="$DATADIR/wikimedias.csv"
readonly DATABASE=$DATADIR/taginfo-languages.db

# shellcheck source=/dev/null
source "$SRCDIR/../util.sh" languages

update_file() {
    local file="$1"
    local url="$2"

    if run_exe curl --silent --fail --location --time-cond "$file" --output "$file" "$url"; then
        return 0
    else
        error=$?
        if [ "$error" = "22" ] || [ "$error" = "7" ] || [ "$error" = "60" ]; then
            print_message "WARNING: Getting ${url} failed. Using old version."
        else
            print_message "ERROR: Could not get ${url}: curl error: $error"
            exit 1
        fi
    fi
}

getting_subtag_registry() {
    print_message "Getting subtag registry..."
    update_file "$REGISTRY_FILE" "$REGISTRY_URL"

    print_message "Running subtag import..."
    run_ruby "$SRCDIR/import_subtag_registry.rb" "$DATADIR"
}

getting_cldr() {
    print_message "Getting CLDR..."
    update_file "$CLDR_FILE" "$CLDR_URL"

    print_message "Unpacking CLDR..."
    rm -fr "$CLDR_DIR"
    mkdir "$CLDR_DIR"
    run_exe unzip -q -d "$CLDR_DIR" "$CLDR_FILE"
}

getting_unicode_scripts() {
    print_message "Getting unicode scripts..."
    update_file "$UNICODE_SCRIPTS_FILE" "$UNICODE_SCRIPTS_URL"
    update_file "$PROPERTY_ALIASES_FILE" "$PROPERTY_ALIASES_URL"

    print_message "Running unicode scripts import..."
    run_ruby "$SRCDIR/import_unicode_scripts.rb" "$DATADIR"
}

getting_unicode_data() {
    print_message "Getting unicode data..."
    update_file "$UNICODE_DATA_FILE" "$UNICODE_DATA_URL"

    print_message "Running unicode data import..."
    run_ruby "$SRCDIR/import_unicode_data.rb" "$DATADIR"
}

getting_wikipedia_sites() {
    print_message "Getting wikipedia sites..."
    update_file "$WIKIMEDIAS_FILE" "$WIKIMEDIAS_URL"

    run_ruby "$SRCDIR/import_wikipedias.rb" "$DATADIR"
}

main() {
    print_message "Start languages..."

    initialize_database "$DATABASE" "$SRCDIR"
    getting_subtag_registry
    getting_cldr
    getting_unicode_scripts
    getting_unicode_data
    getting_wikipedia_sites
    finalize_database "$DATABASE" "$SRCDIR"

    print_message "Done languages."
}

main

