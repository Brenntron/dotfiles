#!/usr/bin/env bash

if [ $(basename $PWD) != "extras" ]
then
        echo "Please run this script from the extras directory"
        exit -1
fi

if [ ! -d snort ]
then
	echo "The snort directory doesn't seem to exist.  Please run init_snort.sh instead."
	exit -1
else
	cd snort
fi

if [ -z $CVSROOT ]
then
	echo -n "Please enter your CVS username [$USER]: "
	read cvs_user

	if [ -z $cvs_user ]
	then
        	cvs_user=$USER
	fi

	export CVSHOST="scm.sfeng.sourcefire.com"
	export CVSROOT=":ext:$cvs_user@scm.sfeng.sourcefire.com:/usr/cvsroot/"
	export CVS_RSH="/usr/bin/ssh"
fi

# Support passing in the version
if [ -z $1 ]
then
	echo -n "Enter the snort version to install from snort.org: "
	read build
else
	build=$1	
fi

snort_build=snort-$build
snort_pkg=$snort_build.tar.gz

echo "Fetching the snort package from snort.org"
wget -q https://snort.org/downloads/snort/$snort_pkg -O $snort_pkg

if [ $? -ne 0 ]
then
        echo "Unable to download snort-$build.tar.gz"
        cd ..
        rm -rf snort
        exit -1
fi

if [ -d snort-current ]
then
	echo "Backing up the old snort-current"
	if [ -d snort-current.bak ]
	then
		echo "Deleting the old backup"
		rm -rf snort-current.bak
	fi
	mv snort-current snort-current.bak
fi

echo "Extracting snort package"
tar -zxf $snort_pkg
mv $snort_build snort-current
rm $snort_pkg

echo "Configuring snort"
cd snort-current
./configure --prefix=/usr/local --enable-sourcefire --enable-gre --enable-mpls --enable-targetbased --enable-ppm --enable-perfprofiling --enable-sourcefire --enable-reload --enable-react 1> /dev/null

if [ $? -ne 0 ]
then
        echo "Error while configuring snort.  Leaving source in place."
        exit -1
fi

echo "Buiding snort. This may take a while"
make -j`sysctl -a | egrep -i 'hw.ncpu' | cut -f 2 -d " "` 1> /dev/null

echo "Checking out the latest SO rules"
cd src
cvs -q co -d so_rules -l sfeng/research/rules/so_rules 1> /dev/null
if [ $? -ne 0 ]
then
        echo "Unable to checkout the so rules"
        exit -1
fi

echo "Building the latest SO rules"
cd so_rules
gmake 1> /dev/null


if [ $? -ne 0 ]
then
        echo "Error while building the SO rules"
        exit -1
fi

exit 0
