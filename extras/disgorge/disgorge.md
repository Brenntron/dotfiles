# Analyst Console Deployment

This system, hurl and disgorge, will build the Analyst Console project
on a remote UNIX host.

The original design was built for the following two purposes:

  1.  To build a tar file of the Analyst Console image to install in a FreeBSD package for production deployment.
  2.  To install the source code into the remote dev/test environment.


## System
This is a system between hurl and disgorge.

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

### Disgorge Backend Setup
To set up the remote dev web server do the following:

  1.  Copy the contents of the extras/disgorge directory to ~/disgorge

        cd extras
        tar czvf disgorge.tar.gz extras/disgorge
        scp disgorge.tar.gz rulesuitest.vrt.sourcefire.com:.
        ssh rulesuitest.vrt.sourcefire.com
        tar xvf disgorge.tar.gz
        
  2.  Rename database in database.yml

        vi ~/disgorge/shared/config/database.yml

    
  3.  Edit the shared/.env file with appropriate values

        vi ~/disgorge/shared/.env
        
  4.  Fill in secret_key_base

        vi ~/disgorge/shared/config/secrets.yml

  5.  Put the ca.pem file in shared/ssh (you may need to scp it to the server first)

        cp ca.pem ~/disgorge/shared/ssh


### For Deployment
In order to build a package for a production deployment,
run hurl with the --deployment switch.

    $ ruby extras/hurl.rb --deployment

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

