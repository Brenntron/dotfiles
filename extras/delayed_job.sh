#!/usr/bin/env bash

CONFIGFILE="/usr/local/etc/analyst-console-escalations/processes.conf"

if [ -f ${CONFIGFILE} ]; then
        . ${CONFIGFILE}
else
        echo configuration file ${CONFIGFILE} does not exist
        exit
fi

# Set the number of each you want run
declare -A processes

processes["delayed_job"]=1

cd ${RAILS_ROOT}

for process in ${!processes[@]}
do
        for x in $(seq 1 ${processes[$process]})
        do
                echo "$1ing: $process"
                if [ $process == "delayed_job" ]
                then
                        HOME=/var/log/analyst-console RAILS_ENV=${RAILS_ENV} GEM_HOME=${RAILS_ROOT}/vendor/bundle/ruby/2.4/gems ${PREFIX}/bin/bundle exec ${RAILS_ROOT}/bin/$process $1
                fi

                if [ $1 == "start" ]
                then
                        sleep 1
                else
                        /bin/rm -f tmp/$process.output
                        /bin/rm -f tmp/snort.pipe.*
                fi
        done
done
