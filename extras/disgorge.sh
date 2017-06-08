#!/usr/bin/env bash


if [ "$#" -lt 1 ]; then
    echo 'USAGE: disgorge.sh tar-file (RELDIR)'
    echo 'Script to uncompress web site source and install'
    echo ''
    echo 'Variables and Defaults:'
    echo 'TARFILE                               First ARG -- path to tar file'
    echo 'RELDIR=<timestamp>                    Second ARG -- subdir for this build'
    echo 'RELBASE=~/disgorge                    Base dir with releases, shared, and current subdirs'
    echo 'RELPATH=$RELBASE/releases/$RELDIR     Dir for source files'
    echo 'SHAREDDIR=$RELBASE/shared             Location of Shared files and dirs'
    echo 'CURRDIR=$RELBASE/current              Path of sym link to source file directory'
    echo 'VENDORDIR=$SHAREDDIR/vendor           Shared vendor directory if exists'
    echo ''
    exit
fi

TARFILE=$1
echo $TARFILE

if [ "$#" -lt 2 ]; then
    RELDIR=`date +%Y%m%d-%H%M%S`
else
    RELDIR=$2
fi

if [ "" == "$RELBASE" ]; then
    RELBASE=~/disgorge
fi
if [ "" == "$RELPATH" ]; then
    RELPATH=$RELBASE/releases/$RELDIR
fi
echo $RELPATH

mkdir $RELPATH
echo '* untarring'
tar -C $RELPATH -xf $TARFILE
TAGDIR=`cd $RELPATH;ls`
echo $TAGDIR

if [ "" == "$SHAREDDIR" ]; then
    SHAREDDIR=$RELBASE/shared
fi

if [ "" == "$CURRDIR" ]; then
    CURRDIR=$RELBASE/current
fi
echo $CURRDIR




echo ''
echo '* Installing'
cd $RELPATH/$TAGDIR

rm -rf extras/ssh
ln -s $SHAREDDIR/.ssh extras/ssh

rm -rf log
ln -s $SHAREDDIR/log .
for file in log/*; do echo "--- Release $RELDIR $TAGDIR" >> $file; done

cp $SHAREDDIR/config/database.yml config

ln -s $SHAREDDIR/.env .

echo '* bundle install'
bundle _1.12.5_ install --no-deployment --frozen --no-local --without development test

echo '* migrations'
bundle exec rake db:migrate

echo '* precompile assets'
bundle exec rake assets:precompile

echo '* svn working folders'
rm $RELPATH/$TAGDIR/extras/working
svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/working/snort-rules
if [ ! -d "$RELPATH/$TAGDIR/extras/snort/snort-rules" ]; then
    svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/snort/snort-rules
fi

echo '* Simlink to $RAILS_ROOT'
rm $CURRDIR
ln -s $RELPATH/$TAGDIR $CURRDIR
cd $CURRDIR

