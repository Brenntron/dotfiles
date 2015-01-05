#!/usr/bin/env bash

if [ $(basename $PWD) != "extras" ]
then
	echo "Please run this script from the extras directory"
	exit -1
fi

echo -n "Please enter your CVS username [$USER]: "
read cvs_user

if [ -z $cvs_user ]
then
	cvs_user=$USER
fi

export CVSHOST="scm.sfeng.sourcefire.com"
export CVSROOT=":ext:$cvs_user@scm.sfeng.sourcefire.com:/usr/cvsroot/"
export CVS_RSH="/usr/bin/ssh"

# Don't overwrite the directory if it exists
if [ -d snort ]
then
	echo "The snort directory seems to already exist"
	exit -1
else
	echo "Creating the snort directory"
	mkdir snort
fi

# Check out the needed configuration directories
cd snort

echo "Checking out the latest config files"
cvs -q co -d etc sfeng/research/rules/etc 1> /dev/null
if [ $? -ne 0 ]
then
	echo "An error occurred while checking out the etc directory"
	cd ..
	rm -rf snort
	exit -1
fi

echo "Cheching out the latest preprocessor files"
cvs -q co -d preprocessor sfeng/research/rules/preprocessor 1> /dev/null
if [ $? -ne 0 ]
then
	echo "An error occurred while checking out the preprocessor directory"
	cd ..
	rm -rf snort
	exit -1
fi

echo "Checking out the latest plaintext rules"
cvs -q co -d rules sfeng/research/rules/snort-rules 1> /dev/null
if [ $? -ne 0 ]
then
	echo "An error occurred while checking out the rules directory"
	cd ..
	rm -rf snort
	exit -1
fi

echo "Starting the snort installer"
cd ..
./install_snort.sh

if [ $? -ne 0 ]
then	
	echo "Looks like the snort install failed"
	exit -1	
else
	echo "Congratulations!  Everything seems to have built without errors."
	exit 0
fi
