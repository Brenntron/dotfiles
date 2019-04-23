#!/usr/bin/env bash


if [[ $# -lt 1 ]]; then
    echo 'USAGE: RAILS_ENV=production disgorge.sh TARFILE (RELDIR)'
    echo 'Script to uncompress web site source and install'
    echo ''
    echo 'Variables and Defaults:'
    echo 'RAILS_ENV                             Cannot be test or development from bundle install --without'
    echo 'TARFILE                               First ARG -- path to tar file'
    echo 'RELDIR=<timestamp>                    Second ARG -- subdir for this build'
    echo 'RELBASE=AC-TESTING/$USER/disgorge     Base dir with releases, shared, and current subdirs'
    echo 'RELPATH=$RELBASE/releases/$RELDIR     Dir for source files'
    echo 'SHARED=SHARED                         SHARED to use shared dir, SKIP to omit'
    echo 'SHAREDDIR=$RELBASE/shared             Location of Shared files and dirs'
    echo 'CURRDIR=$RELBASE/current              Path of sym link to source file directory'
    echo 'VENDORDIR=$SHAREDDIR/vendor           Shared vendor directory if exists'
    echo 'BUNDLE_SHARE=CLEAN                    CLEAN to not use shared, SHARE to use shared, COPY to copy from shared'
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
    RELBASE=/usr/local/AC-TESTING/$USER/disgorge
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
RAILS_ROOT=$RELPATH/$TAGDIR
echo RAILS_ROOT = $RAILS_ROOT
cd $RAILS_ROOT
echo `pwd`




if [ "" == "$RELTMP" ]; then
    RELTMP=$RAILS_ROOT/tmp
fi

if [ "SKIP" != "$SHARED" ]; then
    echo '* using shared files and directories'
    echo $SHAREDDIR
    echo $RAILS_ROOT

    cd $RAILS_ROOT

    if [ -f $SHAREDDIR/config/database.yml ]; then
        echo linking $SHAREDDIR/config/database.yml to $RAILS_ROOT/config/database.yml
        rm config/database.yml
        ln -s $SHAREDDIR/config/database.yml $RAILS_ROOT/config
    fi
    if [ -f $SHAREDDIR/config/secrets.yml ]; then
        echo $SHAREDDIR/config/secrets.yml to $RAILS_ROOT/config/secrets.yml
        rm config/secrets.yml
        ln -s $SHAREDDIR/config/secrets.yml $RAILS_ROOT/config
    fi
    if [ -f $SHAREDDIR/config/config.yml ]; then
        echo $SHAREDDIR/config/config.yml to $RAILS_ROOT/config/config.yml
        rm config/config.yml
        ln -s $SHAREDDIR/config/config.yml $RAILS_ROOT/config
    fi
fi

if [ "SHARE" == "$BUNDLE_SHARE" ]; then
    ln -s $SHAREDDIR/vendor/bundle vendor/bundle
else
    mkdir vendor/bundle
fi

if [ "COPY" == "$BUNDLE_SHARE" ]; then
    echo "* copying vendor bundle"
    cp -R $SHAREDDIR/vendor/bundle vendor
fi

if [ "SKIP" != "$BUNDLE_PACKAGE" ]; then
    echo '* bundle package'
    if [ ! -d vendor/cache ]; then
        mkdir vendor/cache
    fi
    if [ -d vendor/gems ]; then
        cp `find vendor/gems -name '*.gem'` vendor/cache
    fi
    bundle _1.17.1_ package --path vendor/bundle
fi

if [ "SKIP" != "$BUNDLE_INSTALL" ]; then
    echo '* bundle install'
    if [ "DEPLOYMENT" == "$DEPLOYMENT" ]; then
        bundle _1.17.1_ install --deployment --clean --local --path vendor/bundle --without development test profile
    else
        bundle _1.17.1_ install --local --path vendor/bundle
    fi
fi

if [ "SKIP" != "$VISRULEPARSER" ]; then
    echo '* Visruleparser'
    svn export --force https://repo.vrt.sourcefire.com/svn/rr-int/tools/commit-tools/visruleparser.pl $RELPATH/$TAGDIR/extras/
fi

if [ "SKIP" != "$MIGRATE" ]; then
    echo '* migrations'
    bundle exec rake db:migrate
fi

if [ "SKIP" != "$PRECOMPILE" ]; then
    echo '* precompile assets'
    bundle exec rake assets:precompile

    chmod 777 $RELTMP/cache/assets
    umask 000 $RELTMP/cache/assets
    chmod 777 $RELTMP/cache/assets/sprockets
    umask 000 $RELTMP/cache/assets/sprockets
    chmod 777 $RELTMP/cache/assets/sprockets/v3.0
    umask 000 $RELTMP/cache/assets/sprockets/v3.0
    chmod 777 $RELTMP/cache/assets/sprockets/v3.0/*
    umask 000 $RELTMP/cache/assets/sprockets/v3.0/*
    #chmod 777 $RELTMP/cache/assets/sprockets/v3.0/*/*
fi

if [ "SKIP" != "$SVN_WORKING" ]; then
    echo '* svn working folders'
    rm -rf $RELPATH/$TAGDIR/extras/working
    svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/working/snort-rules
    #if [ ! -d "$RELPATH/$TAGDIR/extras/snort/snort-rules" ]; then
    #    svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ $RELPATH/$TAGDIR/extras/snort/snort-rules
    #fi
    ln -s $SHAREDDIR/extras/snort extras/snort

    svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/rulesdocs/ $RELPATH/$TAGDIR/extras/rulesdocs
fi

if [ "" != "$CURRDIR" ]; then
    echo "* simlink $CURRDIR to $RELPATH/$TAGDIR"
    rm $CURRDIR
    ln -s $RELPATH/$TAGDIR $CURRDIR

    cd $CURRDIR

    if [ ! -d tmp ]; then
        mkdir tmp
    fi
    touch tmp/restart.txt

    if [ ! -d tmp/cache ]; then
        mkdir tmp/cache
    fi
    chmod 777 tmp/cache/
fi

if [ "" != "$VERSION" ]; then
    echo "* tar output"
    echo VERSION=$VERSION
    echo $VERSION > public/version.html
    if [ -d "public/escalations" ]; then
        echo $VERSION > public/escalations/version.html
    fi
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
    bash -c "cd $RELPATH; tar czhf $VERSION.tar.gz $VERSION"
fi

if [ "" != "$VERSION" ]; then
RAILS_ROOT=$RELPATH/$VERSION
else
RAILS_ROOT=$RELPATH/$TAGDIR
fi

if [ "SKIP" != "$SHARED" ]; then
    echo '* using shared files and directories'
    echo $SHAREDDIR
    echo $RAILS_ROOT

    cd $RAILS_ROOT
    
    if [ -d $SHAREDDIR/tmp ]; then
        rm -rf tmp
        ln -s $SHAREDDIR/tmp .
    fi

    if [ ! -d $SHAREDDIR/tmp ]; then
        echo making shared directory - $SHAREDDIR/tmp
        mkdir $SHAREDDIR/tmp
    fi
    
    if [ -d $RAILS_ROOT/tmp ]; then
        rm -rf $RAILS_ROOT/tmp
    fi
    ln -s $SHAREDDIR/tmp $RAILS_ROOT

    if [ ! -d $SHAREDDIR/nvd ]; then
        mkdir $SHAREDDIR/nvd
    fi
    rm -rf $RAILS_ROOT/lib/data/nvd
    ln -s $SHAREDDIR/nvd $RAILS_ROOT/lib/data

    if [ -d $SHAREDDIR/log ]; then
        if [ -d $RAILS_ROOT/log ]; then
            rm -rf $RAILS_ROOT/log
        fi
        ln -s $SHAREDDIR/log $RAILS_ROOT
        if [ -f log/staging.log ]; then
            echo "--- Release $RELDIR $TAGDIR" >> log/staging.log
        fi
        if [ -f log/development.log ]; then
            echo "--- Release $RELDIR $TAGDIR" >> log/development.log
        fi
    fi

    if [ -f $SHAREDDIR/config/database.yml ]; then
        echo linking $SHAREDDIR/config/database.yml to $RAILS_ROOT/config/database.yml
        if [ -f config/database.yml ]; then
            rm config/database.yml
        fi
        ln -s $SHAREDDIR/config/database.yml $RAILS_ROOT/config
    fi
    if [ -f $SHAREDDIR/config/secrets.yml ]; then
        echo $SHAREDDIR/config/secrets.yml to $RAILS_ROOT/config/secrets.yml
        if [ -f config/secrets.yml ]; then
            rm config/secrets.yml
        fi
        ln -s $SHAREDDIR/config/secrets.yml $RAILS_ROOT/config
    fi
    if [ -f $SHAREDDIR/config/config.yml ]; then
        echo $SHAREDDIR/config/config.yml to $RAILS_ROOT/config/config.yml
        rm config/config.yml
        ln -s $SHAREDDIR/config/config.yml $RAILS_ROOT/config
    fi
fi

echo *Linking new build to local server location

cd /usr/local/AC-TESTING/$USER/
rm public_html
ln -s $RAILS_ROOT public_html
cd public_html
touch tmp/restart.txt

if [ "" != "$VERSION" ]; then
echo copying $RAILS_ROOT.tar.gz  to  /nfs/research/distfiles
cp $RAILS_ROOT.tar.gz /nfs/research/distfiles
fi


