#!/bin/bash
#Docker script to move certs to the container folder to be inserted into the container in the right place


#move certs to where the script is run which should be extras/
echo "copying certs to local folder"

cp /usr/local/etc/tess-ca_cert.pem .
cp /usr/local/etc/tess-client.pem .
cp /usr/local/etc/tess-pkey.key .
cp /usr/local/etc/sds-certificate.pem .
cp /usr/local/etc/sds-pkey.pem .

echo "starting docker build script"

#run the docker command to build the container
docker compose build

#wait for the docker command to finish
PID = $!
wait $PID

echo "Finished building. Removing certs from local folder"

#remove the certs from extras/ so they arent accidentlly checked into git
rm -f tess-ca_cert.pem
rm -f tess-client.pem
rm -f tess-pkey.key
rm -f sds-certificate.pem
rm -f sds-pkey.pem

if [ ! -z "$1" ]
  then
    if ([ "$1" == "start" ]); then
      echo "starting image"
      docker compose start
    elif ([ "$1" == "up" ]); then
      echo "creating and starting image"
      docker compose up
    else
      echo "Not a recognised argument. Use up or start."
    fi
fi

echo "Thanks for playing!"