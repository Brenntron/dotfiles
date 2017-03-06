#!/usr/bin/env bash
# USAGE: synch_rules.sh <filenames>
# parses rule files and runs rails script to load into synched_rules table.


grep -Hnv "^\s*#" $* | bundle exec rails runner extras/synch_rules.rb


