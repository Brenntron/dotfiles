#!/usr/bin/env bash


if [[ $# -lt 1 ]]; then
    echo 'USAGE: RAILS_ENV=production disgorge.sh TARFILE (RELDIR)'
    echo 'Script to uncompress web site source and install'
    echo ''
    echo 'Variables and Defaults:'
    echo 'RAILS_ENV                             Cannot be test or development from bundle install --without'
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

echo VERSION=$VERSION

TARFILE=$1
echo $TARFILE

if [[ $# -lt 2 ]]; then
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
echo '* installing'
echo $RELPATH
echo $TAGDIR
cd $RELPATH/$TAGDIR

if [ "SKIP" != "$SHARED" ]; then
    echo '* using shared files and directories'

    rm -rf extras/ssh
    ln -s $SHAREDDIR/ssh extras/ssh

    rm -rf log
    ln -s $SHAREDDIR/log .
    if [ -f log/staging.log ]; then
        echo "--- Release $RELDIR $TAGDIR" >> log/staging.log
    fi
    if [ -f log/development.log ]; then
        echo "--- Release $RELDIR $TAGDIR" >> log/development.log
    fi

    cp $SHAREDDIR/config/database.yml config
    cp $SHAREDDIR/config/secrets.yml config
fi

if [ "SKIP" != "$BUNDLE_PACKAGE" ]; then
    echo '* bundle package'
    if [ ! -d vendor/cache ]; then
        mkdir vendor/cache
    fi
    if [ -d vendor/gems ]; then
        cp `find vendor/gems -name '*.gem'` vendor/cache
    fi
    bundle _1.14.6_ package --path vendor/bundle
fi

if [ "SKIP" != "$BUNDLE_INSTALL" ]; then
    echo '* bundle install'
    bundle _1.14.6_ install --deployment --local --path vendor/bundle --without development test
fi

if [ "SKIP" != "$MIGRATE" ]; then
    echo '* migrations'
    bundle exec rake db:migrate
fi

if [ "SKIP" != "$PRECOMPILE" ]; then
    echo '* precompile assets'
    bundle exec rake assets:precompile
fi

if [ "SKIP" != "$SVN_WORKING" ]; then
    echo '* svn working folders'
    rm -rf $RELPATH/$TAGDIR/extras/working
    svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/working/snort-rules
    #if [ ! -d "$RELPATH/$TAGDIR/extras/snort/snort-rules" ]; then
    #    svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/snort/snort-rules
    #fi
    ln -s $SHAREDDIR/extras/snort extras/snort

    svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/ruledocs/ $RELPATH/$TAGDIR/extras/ruledocs
fi

if [ "" != "$CURRDIR" ]; then
    echo "* simlink $CURRDIR to $RELPATH/$TAGDIR"
    rm $CURRDIR
    ln -s $RELPATH/$TAGDIR $CURRDIR
    cd $CURRDIR
fi

if [ "" != "$VERSION" ]; then
    echo "* tar output"
    echo VERSION=$VERSION
    rm -rf tmp
    #mkdir tmp
    rm -rf log
    rm config/database.yml
    rm config/secrets.yml

    if [ "$TAGDIR" != "$VERSION" ]; then
       echo mv $TAGDIR $VERSION
       bash -c "cd $RELPATH; mv $TAGDIR $VERSION"
    fi
    echo "* tar file = $VERSION.tar.gz"
    bash -c "cd $RELPATH; tar czf $VERSION.tar.gz $VERSION"
fi


