#!/usr/bin/env bash

# Set the number of each you want run
declare -A processes

processes["poller"]=5
processes["client_local"]=10
processes["client_all"]=10
processes["rules_updater"]=1	# Only run 1
processes["committer"]=1		# Only run 1	
processes["job_cleaner"]=1		# Only run 1

if [ "$1" == "start" ]
then
	# Make sure we add the ssh key for cvs
	ulimit -c 0
	ssh-agent > tmp/ssh.script
	source tmp/ssh.script
	chmod 600 extras/ssh/id_rsa
	ssh-add extras/ssh/id_rsa

elif [ "$1" == "stop" ]
then
	source tmp/ssh.script
	ssh-agent -k
	rm tmp/ssh.script
else
	echo "Usage: $0 <start|stop>"
	exit
fi

for process in ${!processes[@]}
do
	for x in $(seq 1 ${processes[$process]})
	do
		./script/$process $1

		if [ $1 == "start" ]
		then
			sleep 1
		else
			rm tmp/$process.output
			rm tmp/snort.pipe.*
		fi
	done
done
