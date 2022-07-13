FROM ruby:2.7.4

WORKDIR /analyst_console_escalations
COPY . /analyst_console_escalations
ADD http://wwwint.vrt.sourcefire.com/ca.pem /usr/local/share/ca-certificates/vrt.crt
RUN update-ca-certificates
RUN apt-get update

RUN apt-get -y install iputils-ping
RUN apt-get -y install nodejs
RUN apt-get -y install cmake
RUN apt-get -y install vim

RUN gem install httparty
RUN gem install httpi -v 2.5.0
RUN gem install curb -v 0.9.11
RUN gem install json -v 2.5.1

RUN curl --header "PRIVATE-TOKEN: JTgQg6TEdjyzj7BJNyU2" "https://gitlab.vrt.sourcefire.com/api/v4/projects/1390/repository/files/peake-bridge-client-0.1.0.0.gem/raw?ref=master" -o peake-bridge-client.gem
RUN gem install --local /analyst_console_escalations/vendor/gems/peake-bridge-client/peake-bridge-client.gem

RUN gem install resque
RUN gem install bundler

RUN cd /analyst_console_escalations; bundle

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]
EXPOSE 3002

CMD ["rails", "s", "-b", "0.0.0.0", "-p", "3002"]