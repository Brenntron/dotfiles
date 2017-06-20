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

#if [ "" == "$CURRDIR" ]; then
#    CURRDIR=$RELBASE/current
#fi
#echo $CURRDIR
if [ "" != "$CURRDIR" ]; then
    echo $CURRDIR
fi



echo ''
echo '* Installing'
echo $RELPATH
echo $TAGDIR
cd $RELPATH/$TAGDIR

if [ "SKIP" != "$SHARED" ]; then
    echo '* using shared files and directories'

    rm -rf extras/ssh
    ln -s $SHAREDDIR/.ssh extras/ssh

    rm -rf log
    ln -s $SHAREDDIR/log .
    for file in log/*; do echo "--- Release $RELDIR $TAGDIR" >> $file; done

    cp $SHAREDDIR/config/database.yml config

    ln -s $SHAREDDIR/.env .
fi

echo '* bundle package'
bundle _1.14.6_ package --frozen --path vendor/bundle

echo '* bundle install'
bundle _1.14.6_ install --deployment --frozen --local --path vendor/bundle --without development test

if [ "SKIP" != "$MIGRATE" ]; then
    echo '* migrations'
    bundle exec rake db:migrate
fi

echo '* precompile assets'
bundle exec rake assets:precompile

if [ "SKIP" != "$SVN_WORKING" ]; then
    echo '* svn working folders'
    rm -rf $RELPATH/$TAGDIR/extras/working
    svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/working/snort-rules
    if [ ! -d "$RELPATH/$TAGDIR/extras/snort/snort-rules" ]; then
        svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/snort/snort-rules
    fi
fi

if [ "" != "$CURRDIR" ]; then
    echo '* Simlink to $RAILS_ROOT'
    rm $CURRDIR
    ln -s $RELPATH/$TAGDIR $CURRDIR
    cd $CURRDIR
fi

if [ "" != "$VERSION" ]; then
    rm -rf tmp
    #mkdir tmp
    rm -rf log
    rm config/database.yml
    rm config/secrets.yml

    bash -c "cd $RELPATH; mv $TAGDIR $VERSION; tar czf $VERSION.tar.gz $VERSION"
fi


