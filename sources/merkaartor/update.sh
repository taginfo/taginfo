#!/bin/sh
#
#  Taginfo source: Merkaartor
#
#  update.sh DIR
#

set -e

DIR=$1

if [ "x" = "x$DIR" ]; then
    echo "Usage: update.sh DIR"
    exit 1
fi

echo -n "Start merkaartor: "; date

DATABASE=$DIR/taginfo-merkaartor.db

rm -f $DATABASE

echo "Getting resources..."
if [ -d $DIR/git-source ]; then
    cd $DIR/git-source
    git pull
    cd -
else
    git clone http://git.gitorious.org/merkaartor/main.git $DIR/git-source
fi

echo "Running pre.sql..."
sqlite3 $DATABASE <pre.sql

echo "Running import..."
./import_merkaartor.rb $DIR

echo "Running post.sql..."
sqlite3 $DATABASE <post.sql

echo -n "Done merkaartor: "; date

