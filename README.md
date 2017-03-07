talos_api
=========

# Environment Installation

install the ca.pem found here
https://sites.google.com/a/sourcefire.com/vrt/training-documentation/authentication
in
/System/Library/OpenSSL/certs/


1.  You will need certain perl modules

    install cpanminus
    
        $ curl -L https://cpanmin.us | perl - --sudo App::cpanminus
        install perl modules
        $ sudo cpanm WWW::Mechanize
        $ sudo cpanm Try::Tiny


2.  add CANVAS_ROOT to your profile env file

        export CANVAS_ROOT=/Users/<username>/<talos_api_directory>/extras
    
3.  install visruleparser dependancies

    Net::Snort::Parser::Rule
    
        $ svn co https://repo.vrt.sourcefire.com/svn/vrt-systems/trunk/buildtools/common/lib/net-snort-parser
        $ cd net-snort-parser
        $ perl Makefile.pl && make && make test
        $ sudo make install

    set up perl to be able to run visruleparser or make sure visruleparser is using /usr/local/bin/perl not /usr/bin/perl

4.  put a copy of snort rules in the extras directory.
    
    *   download latest snort rule set from [snort.org](http://snort.org)
    *   extract rules to
    
            extras/snort/etc
            extras/snort/preproc_rules
            extras/snort/rules
    
    *   extract snort so rules to
    
            extras/snort/so_rules
    
    run synch script to load rules.

        $ ./extras/resynch.sh
    
5.  Make sure active MQ is running
    
        $ brew install activemq
        $ activemq start
        $ activemq console
  



6.  On the server we need to do this
    
    regenerating the keytab
    
        $ sudo msktutil -u -s HTTP
        $ sudo cp /etc/krb5.keytab /usr/local/etc/apache22/rulesuitest.keytab
        $ sudo ktutil -k /usr/local/etc/apache22/rulesuitest.keytab remove -p rulesuitest\$
        $ sudo ktutil -k /usr/local/etc/apache22/rulesuitest.keytab remove -p host/rulesuitest.vrt.sourcefire.com
    
    
        $ bundle exec rails runner lib/poller.rb
        $ bundle exec rails runner lib/client_local.rb

7. Production also needs to have mysql set up




8.  When bundling:

    * if you have problems with eventmachine, you might need to do this:
    
            $ gem install eventmachine --version=1.0.8 -- --with-cppflags=-I/usr/local/opt/openssl/include
    
    * if you have problems with rmagick, you might need to do this as a solution for Sierra:
    
            $ brew install imagemagick@6
            $ brew link --force imagemagick@6


9.  dont forget to migrate the database

10. Below is just to set up a locally signed ssh key not really all that necessary.

        http://www.railway.at/2013/02/12/using-ssl-in-your-local-rails-environment/
    
    SSL self signed localhost for rails start to finish, no red warnings.


## 1) Create your private key (any password will do, we remove it below)

$ openssl genrsa -des3 -out server.orig.key 2048

## 2) Remove the password

$ openssl rsa -in server.orig.key -out server.key

## 3) Generate the csr (Certificate signing request) (Details are important!)

$ openssl req -new -key server.key -out server.csr

**IMPORTANT**
*MUST have localhost.ssl as the common name to keep browsers happy*
*(has to do with non internal domain names ... which sadly can be*
*avoided with a domain name with a "." in the middle of it somewhere)*
*Country Name (2 letter code) [AU]:*
*...*
*Common Name: localhost.ssl*
*...*

## 4) Generate self signed ssl certificate

$ openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

## 5) Finally Add localhost.ssl to your hosts file

$ echo "127.0.0.1 localhost.ssl" | sudo tee -a /etc/hosts


# Running the Server

## Run the web server

*   To use with guard

        $bundle exec foreman start -f Procfile.dev
    
*   To just run with rails

        $bundle exec rails s
    
* If you *want* to use thin

        $thin start -p 3000
        $thin start -p 3000 --ssl --ssl-verify --ssl-key-file ~/.ssl/server.key --ssl-cert-file ~/.ssl/server.crt


## Add server.crt as trusted !!SYSTEM!! (not login) cert in the mac osx keychain
 *Open keychain tool, drag .crt file to system, and trust everything.


## View test page
$ open https://localhost:3000

**Notes:**
*1) Https traffic and http traffic can't be served from the same thin process. If you want*
*both you need to start two instances on different ports.*



# Tests

### Guard

---

run all tests

    $ bundle exec guard

run all test with @now tag

    $ bundle exec guard -g now

### Cucumber

---

run individual feature files

    $ bundle exec cucumber features/users.feature --require features




# Deploying this app to production
run the deploy_api.rb file using:
ruby deploy_api.rb

this will build the app locally, package it up, and scp it up to the server. 

