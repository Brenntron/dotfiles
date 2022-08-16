# Analyst Console Escalations

## TL;DR
Run this command to build your image for the first time
```sh
./extras/docker_compose.sh
```

After you have built this image once, you can then always launch it with
```sh
docker-compose up
```

The application always launches at
`localhost:9002`

## Developer Setup

### Prerequisites

* Have [Docker](https://www.docker.com) installed on your machine.
* Complete the setup steps found in the [Databases for Docker](https://gitlab.vrt.sourcefire.com/talosweb/databases_for_docker) repo. Especially make sure that the data import step succeeds. **Pro Tip:** The most reliable way to do this is with the command line methods, documented in the Readme.
* Make sure your database container is running.

### Build the Docker image

Make sure the following files exist on your machine (you need these for things other than this repo anyway, so you probably added them as part of some other onboarding):

- /usr/local/etc/tess-ca_cert.pem
- /usr/local/etc/tess-client.pem
- /usr/local/etc/tess-pkey.key
- /usr/local/etc/sds-certificate.pem
- /usr/local/etc/sds-pkey.pem
- /usr/local/etc/trusted-certificates.pem

Run this command to build your image for the first time
```sh
./extras/docker_compose.sh
```
(this step takes a long time, but you only have to do it once)

After you have built this image once, you can then always launch it with
```sh
docker-compose up
```

### Debugging

*Note: The steps below are only enabled by the `stdin_open: true` and `tty: true` options in the docker-compose file. If we have to remove those lines when deploying for real, these steps won't work.*

With the container running, you can open another Terminal window and run
 
 ```sh
 docker container ls 
 ```

 to find the container ID. Then,

 ```sh
 docker attach <id here>
 ```

 and in that window you can navigate break points.