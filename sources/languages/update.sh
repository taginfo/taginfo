#!/bin/sh
#
#  Taginfo source: Languages
#
#  update.sh DIR
#

set -e

DIR=$1
REGISTRY_URL="http://www.iana.org/assignments/language-subtag-registry"
REGISTRY_FILE="$DIR/language-subtag-registry"
CLDR_URL="http://unicode.org/Public/cldr/latest/core.zip"
CLDR_FILE="$DIR/cldr-core.zip"
CLDR_DIR="$DIR/cldr"
UNICODE_SCRIPTS_URL="http://www.unicode.org/Public/UNIDATA/Scripts.txt"
UNICODE_SCRIPTS_FILE="$DIR/Scripts.txt"
PROPERTY_ALIASES_URL="http://www.unicode.org/Public/UNIDATA/PropertyValueAliases.txt"
PROPERTY_ALIASES_FILE="$DIR/PropertyValueAliases.txt"

DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo "`$DATECMD` Start languages..."

EXEC_RUBY="$TAGINFO_RUBY"
if [ "x$EXEC_RUBY" = "x" ]; then
    EXEC_RUBY=ruby
fi
echo "Running with ruby set as '${EXEC_RUBY}'"

DATABASE=$DIR/taginfo-languages.db

rm -f $DATABASE

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Getting subtag registry..."
curl --silent --time-cond $REGISTRY_FILE --output $REGISTRY_FILE $REGISTRY_URL

echo "`$DATECMD` Running subtag import..."
$EXEC_RUBY ./import_subtag_registry.rb $DIR

echo "`$DATECMD` Getting CLDR..."
curl --silent --location --time-cond $CLDR_FILE --output $CLDR_FILE $CLDR_URL

echo "`$DATECMD` Unpacking CLDR..."
rm -fr $CLDR_DIR
mkdir $CLDR_DIR
unzip -q -d $CLDR_DIR $CLDR_FILE

echo "`$DATECMD` Getting unicode scripts..."
curl --silent --location --time-cond $UNICODE_SCRIPTS_FILE --output $UNICODE_SCRIPTS_FILE $UNICODE_SCRIPTS_URL
curl --silent --location --time-cond $PROPERTY_ALIASES_FILE --output $PROPERTY_ALIASES_FILE $PROPERTY_ALIASES_URL

echo "`$DATECMD` Running unicode scripts import..."
$EXEC_RUBY ./import_unicode_scripts.rb $DIR

echo "`$DATECMD` Running post.sql..."
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done languages."

