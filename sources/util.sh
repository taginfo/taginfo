#!/bin/bash
#------------------------------------------------------------------------------
#
#  Taginfo utility functions
#
#  util.sh SCRIPT_NAME
#
#  (The SCRIPT_NAME is used for logging)
#
#------------------------------------------------------------------------------

set -e
set -u

readonly TAGINFO_SCRIPT="$1"

if [ ! -v LAST_MESSAGE_TIMESTAMP ]; then
    typeset -i -x LAST_MESSAGE_TIMESTAMP=$(date +%s)
fi

print_message_impl() {
    local function="$1"; shift
    local message="$*"

    local timestamp=$(date +%Y-%m-%dT%H:%M:%S)
    local -i this_message_timestamp=$(date +%s)
    local -i elapsed=$(( ( $this_message_timestamp - $LAST_MESSAGE_TIMESTAMP ) / 60 ))

    printf "%s | %d | %s | %s | %s\n" "$timestamp" "$elapsed" "$TAGINFO_SCRIPT" "$function" "$message"
}

print_message() {
    local message="$1"

    print_message_impl "${FUNCNAME[1]}" "$message"
}

ruby_command_line() {
    echo -n -E "env - ${TAGINFO_RUBY:-ruby} -E utf-8 -w -I $SRCDIR/lib"
}

get_config() {
    local name="$1"
    local default="${2:-}"

    $(ruby_command_line) $SRCDIR/../../bin/taginfo-config.rb "$name" "$default"
}

run_ruby() {
    local logfile=""
    if [[ $1 == "-l"* ]]; then
        logfile="${1:2}"
        shift
    fi

    print_message_impl "${FUNCNAME[1]}" "Running '$(ruby_command_line) $@'..."

    if [ -z $logfile ]; then
        $(ruby_command_line) "$@"
    else
        print_message_impl "${FUNCNAME[1]}" "  Logging to '${logfile}'..."
        $(ruby_command_line) "$@" >$logfile
    fi
}

run_exe() {
    local logfile=""
    if [[ $1 == "-l"* ]]; then
        logfile="${1:2}"
        shift
    fi

    print_message_impl "${FUNCNAME[1]}" "Running '$@'..."

    if [ -z $logfile ]; then
        env - $@
    else
        print_message_impl "${FUNCNAME[1]}" "  Logging to '${logfile}'..."
        env - $@ >$logfile
    fi
}

run_sql() {
    local -a macros=()

    while [[ $1 == *=* ]]; do
        macros+=($1)
        shift;
    done

    local database="$1"
    local sql_file="$2"
    local message="${3:-Running SQL script '${sql_file}' on database '${database}'...}"

    print_message_impl "${FUNCNAME[1]}" "$message"

    local SQLITE="sqlite3 -bail -batch $database"
    if [ ${#macros[@]} -eq 0 ]; then
        $SQLITE <$sql_file
    else
        local sql="$(<$sql_file)"
        for i in ${macros[@]}; do
            print_message_impl "${FUNCNAME[1]}" "  with parameter: $i"
            sql=${sql//__${i%=*}__/${i#*=}}
        done
        echo -E "$sql" | $SQLITE
    fi
}

initialize_database() {
    local database="$1"
    local sourcedir="$2"

    rm -f $database
    run_sql $database $sourcedir/../init.sql
    run_sql $database $sourcedir/pre.sql
}

finalize_database() {
    local database="$1"
    local sourcedir="$2"

    run_sql $database $sourcedir/post.sql
}

get_bindir() {
    (cd $SRCDIR; realpath $(get_config sources.db.bindir ../../tagstats))
}

