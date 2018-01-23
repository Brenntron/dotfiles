# Analyst Console Deployment

This system, hurl and disgorge, will build the Analyst Console project
on a remote UNIX host.

The original design was built for the following two purposes:

  1.  To build a tar file of the Analyst Console image to install in a FreeBSD package for production deployment.
  2.  To install the source code into the remote dev/test environment.


## System
This is a system including hurl and disgorge.
The hurl system installs a tar file onto the target system,
and kicks off the disgorge system.
The disgorge system expands the tar file and sets up the application,
optionally re-tarring the app to deliver to OPS to use as their input to build the FreeBSD package.

### Hurl
The hurl part is a ruby script which runs on the local development environment, such as a laptop.
The hurl script `extras/hurl.rb` will:

  1.  Check out source code from our internal github server.
  2.  Tar the files into a tar file.
  3.  Copy (hurl) the tar file onto the remote host.
  4.  Kick off the disgorge process on the remote host.

### Disgorge
The disgorge part is a shell script which must reside on the remote host to install and build the project image on that host.
The disgorge script `extras/disgorge.sh` will (in some cases optionally):

  1.  Create a working or destination directory specific to the release version.
  2.  Untar the tar file of the source.
  3.  Set up symbolic links to shared files.
  4.  bundle package
  5.  bundle install
  6.  Run the database schema migrations.
  7.  Precompile assets.
  8.  Initialize the subversion working directories for Analyst Console.
  9.  Create a symbolic link to the version installed.
  10. Retar the file image to be delivered in order to build the package for a production release.



## Using the System

### Prerequisite Disgorge Setup
A prerequisite for much of the system is setting up the Disgorge Backend.
Follow the instructions in the section below.

Also, by default, hurl assumes you have a `../releases` directory
*(reative to the current working directory when you run hurl)*
for it to work in.

Make sure to install the exact version of bundler 
```
gem install bundler -v 1.16.1
```

### Disgorge Backend Setup
To set up the remote dev web server do the following:

1.  First you will need a writable local directory.

    Rather than under your home (~) directory (which is an NFS mount and very slow),
    a directory unser /usr/local/AC-TESTING has been provided for each developer.
    There should be a disgorge directory under this named `disgorge`.
    
        /usr/local/AC-TESTING/`whoami`/disgorge

    We will call this the $RELBASE, as in
    
        $ cd /usr/local/AC-TESTING/`whoami`
        $ mkdir disgorge
        $ export RELBASE=/usr/local/AC-TESTING/`whoami`/disgorge

1.  Copy the contents of the extras/disgorge directory to ~/disgorge

    From laptop:

        $ cd extras
        $ tar czvf disgorge.tar.gz disgorge
        $ scp disgorge.tar.gz rulesuitest.vrt.sourcefire.com:/usr/local/AC-TESTING/`whoami`
        $ ssh rulesuitest.vrt.sourcefire.com
        $ cd /usr/local/AC-TESTING/`whoami`
        $ tar xvf disgorge.tar.gz
        $ chmod go+w disgorge/shared/log disgorge/shared/tmp
    
1.  Your directory should look like this.

        $ find disgorge
        disgorge
        disgorge/releases
        disgorge/releases/.keep
        disgorge/deployment.env
        disgorge/disgorge.sh
        disgorge/shared
        disgorge/shared/config
        disgorge/shared/config/secrets.yml
        disgorge/shared/config/database.yml
        disgorge/shared/config/config.yml
        disgorge/shared/.env
        disgorge/shared/log
        disgorge/shared/log/.keep
        disgorge/shared/tmp
        disgorge/shared/tmp/.keep
        disgorge/shared/vendor
        disgorge/shared/vendor/bundle
        disgorge/shared/vendor/bundle/.keep
        disgorge/shared/extras
        disgorge/shared/extras/snort
        disgorge/shared/extras/snort/.keep
        disgorge/development.env
        disgorge/disgorge.md

        $ ls -l disgorge/shared/
        total 20
        drwxr-xr-x  2 marlpier  wheel  512 Jan 23 09:13 config
        drwxr-xr-x  3 marlpier  wheel  512 Nov 10 12:35 extras
        drwxrwxrwx  2 marlpier  wheel  512 Jan 23 08:48 log
        drwxrwxrwx  3 marlpier  wheel  512 Jan 23 09:13 tmp
        drwxr-xr-x  3 marlpier  wheel  512 Nov 10 12:35 vendor

1.  Rename database in database.yml

        $ vi shared/config/database.yml

1.  Edit the shared/.env file with appropriate values

        $ vi shared/.env
    
1.  Fill in secret_key_base

        $ vi shared/config/secrets.yml



### For Deployment
In order to build a package for a production deployment,
First make sure there is a tag in git for what you are trying to deploy.
run hurl with the --deployment switch.
also be sure to use the --version switch as well
finally the tag should be added to the command. If it is not added, the zip that is created will be called master.tar.gz


    $ ruby extras/hurl.rb --deployment --version=analyst-console-X.X.X vX.X.X

This will get the source code from git,
and build the tar file needed to deliver for building the FreeBSD package.
The system will use rulesuitest as a build machine
and leave the resulting tar file on rulesuitest.

Notice that the directory tree image of Analyst Console in the resulting tar file
will omit certain directories, as intended for the port which builds the FreeBSD package.

See Options section.


### For Dev Environment
To install code onto a remote dev/test environment,
run hurl with the --development switch.

    $ ruby extras/hurl.rb --development

This will get the source from git,
install the directory tree image for Analyst Console,
and make a symbolic link to the newly installed code.

See Options section.


### Options

#### Help
List the options with the --help switch.

    $ ruby extras/hurl.rb --help

#### Get Source
You can get the source for a specific branch or tag.
You can alternatively use a specified tar file of the source.
By default, (no option given)
`hurl` will use your current branch on your local git,
and get the source from origin with that branch name.

The `--no-build` switch will skip getting the source,
and instead, just copy the given tar file and use it to install on the remote host.

#### Optional Steps
Steps can be skipped:
-   Skip getting the source and retarring with the `--no-build` switch.
-   Skip the upload to the remote host with the `--no-upload` switch.
-   Skip the untarring, building, and installing with the `--no-disgorge` switch.

Additional optional steps:
-   Add precompiling assets on the client,
    to be included in the tar for upload to the remote host with the `--assets` switch.
-   Add a `bundle --deployment` step,
    for the vendor/bundle directory to be included in the tar for upload to the remote host
    with the `--vendor-bundle` switch.

