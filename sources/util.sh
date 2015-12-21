#!/bin/bash
#------------------------------------------------------------------------------
#
#  Taginfo utility functions
#
#------------------------------------------------------------------------------

set -e

if [ -z $LAST_MESSAGE_TIMESTAMP ]; then
    typeset -i -x LAST_MESSAGE_TIMESTAMP=$(date +%s)
fi

print_message_impl() {
    local script="$1"; shift
    local function="$1"; shift
    local message="$*"

    local timestamp=$(date +%Y-%m-%dT%H:%M:%S)
    local -i this_message_timestamp=$(date +%s)
    local -i elapsed=$(( ( $this_message_timestamp - $LAST_MESSAGE_TIMESTAMP ) / 60 ))

    printf "%s | %d | %s | %s | %s\n" "$timestamp" "$elapsed" "$script" "$function" "$message"
}

print_message() {
    local message="$1"

    print_message_impl "$TAGINFO_SCRIPT" "${FUNCNAME[1]}" "$message"
}

run_ruby() {
    local logfile=""
    if [[ $1 == "-l"* ]]; then
        logfile="${1:2}"
        shift
    fi

    local exec_ruby="${TAGINFO_RUBY:-ruby} -E utf-8 -w"
    print_message_impl "$TAGINFO_SCRIPT" "${FUNCNAME[1]}" "Running '${exec_ruby} $@'..."

    if [ -z $logfile ]; then
        env - $exec_ruby $@
    else
        print_message_impl "$TAGINFO_SCRIPT" "${FUNCNAME[1]}" "  Logging to '${logfile}'..."
        env - $exec_ruby $@ >$logfile
    fi
}

run_exe() {
    local logfile=""
    if [[ $1 == "-l"* ]]; then
        logfile="${1:2}"
        shift
    fi

    print_message_impl "$TAGINFO_SCRIPT" "${FUNCNAME[1]}" "Running '$@'..."

    if [ -z $logfile ]; then
        env - $@
    else
        print_message_impl "$TAGINFO_SCRIPT" "${FUNCNAME[1]}" "  Logging to '${logfile}'..."
        env - $@ >$logfile
    fi
}

run_sql() {
    local -a macros

    while [[ $1 == *=* ]]; do
        macros+=($1)
        shift;
    done

    local database="$1"
    local sql_file="$2"
    local message="${3:-Running SQL script '${sql_file}' on database '${database}'...}"

    print_message_impl "$TAGINFO_SCRIPT" "${FUNCNAME[1]}" "$message"

    local SQLITE="sqlite3 -bail -batch $database"
    if [ ${#macros[@]} -eq 0 ]; then
        $SQLITE <$sql_file
    else
        local sql="$(<$sql_file)"
        for i in ${macros[@]}; do
            print_message_impl "$TAGINFO_SCRIPT" "${FUNCNAME[1]}" "  with parameter: $i"
            sql=${sql//__${i%=*}__/${i#*=}}
        done
        echo -E "$sql" | $SQLITE
    fi
}

initialize_database() {
    rm -f $DATABASE
    run_sql $DATABASE ../init.sql
    run_sql $DATABASE pre.sql
}

finalize_database() {
    run_sql $DATABASE post.sql
}


