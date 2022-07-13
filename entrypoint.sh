#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f ./tmp/pids/server.pid

for ext_host in "analyst-console-escalations.com"
do
  HOST_IP=`/sbin/ip route|awk '/default/ { print $3 }'`
  echo "${HOST_IP} ${ext_host}" | tee -a /etc/hosts
done

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"