talos_api
=========


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

## 6) Boot thin using foreman

--the cool way-> bundle exec foreman start -f Procfile.dev

--the old way -> $ thin start -p 3000 --ssl --ssl-verify --ssl-key-file ~/.ssl/server.key --ssl-cert-file ~/.ssl/server.crt

## 7) Add server.crt as trusted !!SYSTEM!! (not login) cert in the mac osx keychain
 *Open keychain tool, drag .crt file to system, and trust everything.


## 8) View test page
$ open https://localhost:3000

**Notes:**
*1) Https traffic and http traffic can't be served from the same thin process. If you want*
*both you need to start two instances on different ports.*
