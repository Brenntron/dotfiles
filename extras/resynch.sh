#!/usr/bin/env bash
# USAGE: resynch.sh
# loads all rule files under extras into analyst console.


./extras/synch_rules.sh `find extras/snort/{snort-rules,preprocessor} -name \*.rules | grep -v -i deleted` 2>./synch_rules.err


