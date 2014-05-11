#!/bin/sh
#
#  Taginfo Master DB
#
#  update.sh DIR
#

set -e

DIR=$1

DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo "`$DATECMD` Start master..."

EXEC_RUBY="$TAGINFO_RUBY"
if [ "x$EXEC_RUBY" = "x" ]; then
    EXEC_RUBY=ruby
fi
echo "Running with ruby set as '${EXEC_RUBY}'"

DATABASE=$DIR/taginfo-master.db
HISTORYDB=$DIR/taginfo-history.db

echo "`$DATECMD` Create search database..."

rm -f $DIR/taginfo-search.db
$EXEC_RUBY -pe "\$_.sub!(/__DIR__/, '$DIR')" search.sql | sqlite3 $DIR/taginfo-search.db

rm -f $DATABASE

echo "`$DATECMD` Create master database..."
min_count_tags=`../../bin/taginfo-config.rb sources.master.min_count_tags 10000`
min_count_for_map=`../../bin/taginfo-config.rb sources.master.min_count_for_map 1000`
min_count_relations_per_type=`../../bin/taginfo-config.rb sources.master.min_count_relations_per_type 100`
sqlite3 $DATABASE <languages.sql
$EXEC_RUBY -pe "\$_.sub!(/__DIR__/, '$DIR')" master.sql | sqlite3 $DATABASE
$EXEC_RUBY -pe "\$_.sub!(/__DIR__/, '$DIR')" interesting_tags.sql | $EXEC_RUBY -pe "\$_.sub!(/__MIN_COUNT_TAGS__/, '$min_count_tags')" | sqlite3 $DATABASE
$EXEC_RUBY -pe "\$_.sub!(/__DIR__/, '$DIR')" frequent_tags.sql | $EXEC_RUBY -pe "\$_.sub!(/__MIN_COUNT_FOR_MAP__/, '$min_count_for_map')" | sqlite3 $DATABASE
$EXEC_RUBY -pe "\$_.sub!(/__DIR__/, '$DIR')" interesting_relation_types.sql | $EXEC_RUBY -pe "\$_.sub!(/__MIN_COUNT_RELATIONS_PER_TYPE__/, '$min_count_relations_per_type')" | sqlite3 $DATABASE

echo "`$DATECMD` Updating history database..."
if [ ! -e $HISTORYDB ]; then
    sqlite3 $HISTORYDB < history_init.sql
fi
$EXEC_RUBY -pe "\$_.sub!(/__DIR__/, '$DIR')" history_update.sql | sqlite3 $HISTORYDB

echo "`$DATECMD` Done master."

