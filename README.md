Analyst Console
===============
# Web Site User Interface

# Development and Ops
This section is the steps for Analyst Console maintenance for developers and for ops.

## Environment Installation

### Dependencies

1.  You will need certain perl modules

    install cpanminus
    
        $ curl -L https://cpanmin.us | perl - --sudo App::cpanminus
        install perl modules
        $ sudo cpanm WWW::Mechanize
        $ sudo cpanm Try::Tiny

1.  install visruleparser dependancies

    Net::Snort::Parser::Rule
    
        $ svn co https://repo.vrt.sourcefire.com/svn/vrt-systems/trunk/buildtools/common/lib/net-snort-parser
        $ cd net-snort-parser
        $ perl Makefile.pl && make && make test
        $ sudo make install

    set up perl to be able to run visruleparser or make sure visruleparser is using /usr/local/bin/perl not /usr/bin/perl

1.  Make sure active MQ is running
    
        $ brew install activemq
        $ activemq start
        $ activemq console

### Rails App Setup

1.  Make subversion working folders
    -   Snort Rules directory

        1.  Create `extras/snort` directory
        1.  `cd` to that directory
        1.  `svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/`
        1.  `svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/so_rules/`
        1.  `rm so_rules/*.c so_rules/*.h`
    
    -   Working Directory
        1.  Create `extras/working` directory
        1.  `cd` to that directory
        1.  `svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/`
        1.  `svn co --depth empty https://repo-test.vrt.sourcefire.com/svn/rules/trunk/so_rules/`
    
    -   Public copies of these are found at [snort.org](http://snort.org)
    
1.  bundle

    When bundling:

    * if you have problems with eventmachine, you might need to do this:
    
            $ gem install eventmachine --version=1.0.8 -- --with-cppflags=-I/usr/local/opt/openssl/include
    
    * if you have problems with rmagick, you might need to do this as a solution for Sierra:
    
            $ brew install imagemagick@6
            $ brew link --force imagemagick@6

1.  db setup

        bundle exec rake db:create
        bundle exec rake db:migrate
        bundle exec rake db:seed

1.  Synch rules

        ./extras/synch_rules.sh `find extras/snort/snort-rules/ | grep "\.rules$"`
    
### Credentials

1.  install the ca.pem found here
    https://sites.google.com/a/sourcefire.com/vrt/training-documentation/authentication
    in
    /System/Library/OpenSSL/certs/

1.  regenerating the keytab
    
        $ sudo msktutil -u -s HTTP
        $ sudo cp /etc/krb5.keytab /usr/local/etc/apache22/rulesuitest.keytab
        $ sudo ktutil -k /usr/local/etc/apache22/rulesuitest.keytab remove -p rulesuitest\$
        $ sudo ktutil -k /usr/local/etc/apache22/rulesuitest.keytab remove -p host/rulesuitest.vrt.sourcefire.com
    
        $ bundle exec rails runner lib/poller.rb
        $ bundle exec rails runner lib/client_local.rb

1.  Below is just to set up a locally signed ssh key not really all that necessary.

        http://www.railway.at/2013/02/12/using-ssl-in-your-local-rails-environment/
    
    SSL self signed localhost for rails start to finish, no red warnings.

1.  Create your private key (any password will do, we remove it below)

        $ openssl genrsa -des3 -out server.orig.key 2048

1.  Remove the password

        $ openssl rsa -in server.orig.key -out server.key

1.  Generate the csr (Certificate signing request) (Details are important!)

        $ openssl req -new -key server.key -out server.csr

    **IMPORTANT**
    *MUST have localhost.ssl as the common name to keep browsers happy*
    *(has to do with non internal domain names ... which sadly can be*
    *avoided with a domain name with a "." in the middle of it somewhere)*
    *Country Name (2 letter code) [AU]:*
    *...*
    *Common Name: localhost.ssl*
    *...*

1.  Generate self signed ssl certificate

        $ openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

1.  Finally Add localhost.ssl to your hosts file

    $ echo "127.0.0.1 localhost.ssl" | sudo tee -a /etc/hosts

## Running the Server

### Run the web server

*   To use with guard

        $bundle exec foreman start -f Procfile.dev
    
*   To just run with rails

        $bundle exec rails s
    
* If you *want* to use thin

        $thin start -p 3000
        $thin start -p 3000 --ssl --ssl-verify --ssl-key-file ~/.ssl/server.key --ssl-cert-file ~/.ssl/server.crt


### Add server.crt as trusted !!SYSTEM!! (not login) cert in the mac osx keychain
 *Open keychain tool, drag .crt file to system, and trust everything.


### View test page
$ open https://localhost:3000

**Notes:**
*1) Https traffic and http traffic can't be served from the same thin process. If you want*
*both you need to start two instances on different ports.*



## Tests

### Guard

-   run all tests

        $ bundle exec guard

-   run all test with @now tag

        $ bundle exec guard -g now

### Cucumber

-   run individual feature files

        $ bundle exec cucumber features/users.feature --require features

## Deploying this app to staging
run the deploy_api.rb file using:
ruby deploy_api.rb

this will build the app locally, package it up, and scp it up to the server. 

