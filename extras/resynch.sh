#!/usr/bin/env bash
# USAGE: resynch.sh
# loads all rule files under extras into analyst console.


find extras/snort | grep "\.rules$" | xargs ./extras/synch_rules.sh 2>/dev/null

