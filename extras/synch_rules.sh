#!/usr/bin/env bash
# USAGE: synch_rules.sh <filenames>
# parses rule files and runs rails script to load into synched_rules table.


if [ $# -eq 0 ]; then
    echo "USAGE: synch_rules.sh <filenames>"
    exit 1
fi


grep -Hn "sid:\s*[0-9][0-9]*\s*;" $* | bundle exec rails runner extras/synch_rules.rb


