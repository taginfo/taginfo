#!/bin/sh
#
#  Taginfo source: Projects
#
#  update.sh DIR
#

set -e

DIR=$1
PROJECT_LIST=$DIR/taginfo-projects/project_list.txt

DATECMD='date +%Y-%m-%dT%H:%M:%S'

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo "`$DATECMD` Start projects..."

EXEC_RUBY="$TAGINFO_RUBY"
if [ "x$EXEC_RUBY" = "x" ]; then
    EXEC_RUBY=ruby
fi
echo "Running with ruby set as '${EXEC_RUBY}'"

DATABASE=$DIR/taginfo-projects.db

rm -f $DATABASE

echo "`$DATECMD` Updating projects list..."
if [ -d $DIR/taginfo-projects ]; then
    cd $DIR/taginfo-projects
    git pull
    cd -
else
    git clone https://github.com/taginfo/taginfo-projects.git $DIR/taginfo-projects
fi

echo "`$DATECMD` Running init.sql..."
sqlite3 $DATABASE <../init.sql

echo "`$DATECMD` Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "`$DATECMD` Getting data files..."
$EXEC_RUBY ./import.rb $DIR $PROJECT_LIST

echo "`$DATECMD` Parsing data files..."
$EXEC_RUBY ./parse.rb $DIR

echo "`$DATECMD` Running post.sql..."
sqlite3 $DATABASE <post.sql

echo "`$DATECMD` Done projects."

