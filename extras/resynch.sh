#!/usr/bin/env bash
# USAGE: resynch.sh
# loads all rule files under extras into analyst console.


./extras/synch_rules.sh `find extras/snort -name \*.rules` 2>./synch_rules.err

