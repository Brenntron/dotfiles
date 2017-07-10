#!/usr/bin/env bash

. /usr/local/etc/analyst-console/processes.conf

# Set the number of each you want run
declare -A processes

processes["poller"]=${analyst_console_poller_num}
processes["client_local"]=${analyst_console_client_local_num}
processes["client_all"]=${analyst_console_client_all_num}

cd ${RAILS_ROOT}

for process in ${!processes[@]}
do
	for x in $(seq 1 ${processes[$process]})
	do
	    echo "$1ing: $process"
		                HOME=/var/log/analyst-console RAILS_ENV=production GEM_HOME=./vendor/bundle/ruby/2.3/gems ${PREFIX}/bin/bundle exec ./vendor/bundle/ruby/2.3/bin/rails runner script/$process $1

		if [ $1 == "start" ]
		then
			sleep 1
		else
			/bin/rm tmp/$process.output
			/bin/rm tmp/snort.pipe.*
		fi
	done
done
