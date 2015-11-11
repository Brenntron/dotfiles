require 'fileutils'
require 'digest'


def red(str)
  "\e[31m#{str}\e[0m"
end

# Figure out the name of the current local branch
def self.current_git_branch
  branch = `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
  puts "Deploying branch #{red branch}"
  branch
end


def self.build_API(include_snort)
  puts "delete production folder"
  production_folder = "production"
  if File.directory?("../#{production_folder}")
    puts "production folder exists. deleting it now."
    FileUtils.rm_rf("../#{production_folder}")
  end


  puts "clone the git repo to the production folder"
  system "git clone git@github.com:talosweb/talos_api.git -b #{current_git_branch} --single-branch ../production"

  if File.directory?("../production")
    if File.directory?("vendor/bundle")
      puts "Vendor bundle folder exists. Copying bundle to production."
      `cp -r vendor/bundle ../production/vendor`
      if File.directory?("vendor/cache")
        `cp -r vendor/cache ../production/vendor`
      else
        Dir.chdir "../production"
        system 'bundle package'
        Dir.chdir ".."
      end
    else
      puts "Vendor bundle folder does NOT exist. Building gems."
      puts "build the gems into talos_api/vendor/bundle"
      system 'bundle install --deployment'
      system 'bundle package'
      system 'bundle install --standalone'
      puts "copying gems from talos_api/vendor/bundle to production"
      `cp -r vendor/bundle ../production/vendor`
      `cp -r vendor/cache ../production/vendor`
    end
  else
    raise("Production folder doesnt exist. Probably couldn't clone it from git. Did you upload your branch to git?")
  end

  if (include_snort)
    `cp -r extras/snort ../production/extras`
  end

  puts "compile assets"
  Dir.chdir "../production"
  system 'bundle exec rake assets:precompile'
  Dir.chdir "../talos_api"

  puts "tar up the contents of the production folder"
  system 'cd ../production/ && tar -zcvf ../rulesuitest.tar.gz . && cd ..'
end

def self.upload_API(rebuild_gems)
  puts "create a new folder on the server with a new timestamp"
  timestamp = Time.now.to_i
  `ssh talosweb@rulesuitest.vrt.sourcefire.com << ENDSSH
            mkdir rulesuitest/releases/#{timestamp}
            ENDSSH`

  puts "scp the tarball to talosweb@rulesuitest.vrt.sourcefire.com:rulesuitest/public/app folder"
  system "scp ../rulesuitest.tar.gz talosweb@rulesuitest.vrt.sourcefire.com:rulesuitest/releases/#{timestamp}"

  puts "unload the zip file into timestamp folder"
  `ssh talosweb@rulesuitest.vrt.sourcefire.com << ENDSSH
            cd rulesuitest/releases/#{timestamp}/
            tar -zxvf rulesuitest.tar.gz
            rm rulesuitest.tar.gz
            ENDSSH`

  puts "copy the app config and the database yaml files to the timestamp folder"
  `ssh talosweb@rulesuitest.vrt.sourcefire.com << ENDSSH
            rm /usr/local/www/rulesuitest/releases/#{timestamp}/.env
            rm /usr/local/www/rulesuitest/releases/#{timestamp}/config/database.yml
            rm /usr/local/www/rulesuitest/releases/#{timestamp}/config/app_config.yml
            rm /usr/local/www/rulesuitest/releases/#{timestamp}/config/secrets.yml
            rm /usr/local/www/rulesuitest/releases/#{timestamp}/extras/ssh/ca.pem
            ln -s /usr/local/www/rulesuitest/releases/shared/.env /usr/local/www/rulesuitest/releases/#{timestamp}/.env
            ln -s /usr/local/www/rulesuitest/releases/shared/secrets.yml /usr/local/www/rulesuitest/releases/#{timestamp}/config/secrets.yml
            ln -s /usr/local/www/rulesuitest/releases/shared/database.yml /usr/local/www/rulesuitest/releases/#{timestamp}/config/database.yml
            ln -s /usr/local/www/rulesuitest/releases/shared/app_config.yml /usr/local/www/rulesuitest/releases/#{timestamp}/config/app_config.yml
            ln -s /usr/local/www/rulesuitest/releases/shared/ssh/ca.pem /usr/local/www/rulesuitest/releases/#{timestamp}/extras/ssh/ca.pem
            ENDSSH`


  puts "simlink the timestamped folder to the app directory"
  `ssh talosweb@rulesuitest.vrt.sourcefire.com << ENDSSH
            rm /usr/local/www/rulesuitest/public/app
            ln -s /usr/local/www/rulesuitest/releases/#{timestamp} /usr/local/www/rulesuitest/public/app
            ENDSSH`


  puts "build the gems locally if folder exists"
  # if vendor folder exists copy that over to this vendor folder other wise build the gems
  # and save a copy of the vendor folder for next time.
  directory_exists = `ssh talosweb@rulesuitest.vrt.sourcefire.com "test -d /usr/local/www/rulesuitest/releases/shared/vendor && echo 1 || echo 0"`
  if (directory_exists.to_i == 1 && rebuild_gems == false)
    puts "copying vendor to vendor"
    `ssh talosweb@rulesuitest.vrt.sourcefire.com << ENDSSH
            echo "copying vendor to vendor"
            rm -rf /usr/local/www/rulesuitest/releases/#{timestamp}/vendor
            cp -r /usr/local/www/rulesuitest/releases/shared/vendor /usr/local/www/rulesuitest/releases/#{timestamp}/vendor
            cd rulesuitest/releases/#{timestamp}/
            bundle install --deployment --without development test
            ENDSSH`
  else
    puts "bundle installing gems"
    `ssh talosweb@rulesuitest.vrt.sourcefire.com << ENDSSH
            echo "bundle installing gems"
            cd rulesuitest/releases/#{timestamp}/
            bundle install --deployment
            rm -rf /usr/local/www/rulesuitest/releases/shared/vendor
            cp -r /usr/local/www/rulesuitest/releases/#{timestamp}/vendor /usr/local/www/rulesuitest/releases/shared/
            ENDSSH`
  end

  puts "add tmp/restart.txt"
  `ssh talosweb@rulesuitest.vrt.sourcefire.com << ENDSSH
            cd rulesuitest/releases/#{timestamp}/
            mkdir tmp
            touch tmp/restart.txt
            ENDSSH`
end

process_api = true
send_upload = true
rebuild_gems = false
include_snort = true

ARGV.each do |a|
  case a
    when "--no-api"
      process_api = false
    when "--no-upload"
      send_upload = false
    when "--rebuild-gems"
      rebuild_gems = true
    when "--no_snort"
      include_snort = false
    when "-h" || "--help"
      puts "This script deploys all the content in the API directory and the UI directory up to the server"
      puts "============"
      puts "Valid flags are"
      puts "--no-api           use this flag to prevent the API from being built and sent to the server"
      puts "--no-upload        apps will be built but they will be prevented from being sent to the server"
      puts "--rebuild-gems     gems are stored in the shared folder on the server. Use this flag to rebuild them."
      puts "--no_snort         Snort rules will not be packaged with the production tarball"
      process_api = false
      send_upload = false
      break
    else
      puts "One of your flags '#{a}' is not valid. Try again. use -h or --help"
      process_api = false
      send_upload = false
      break
  end
end

if process_api
  begin
    build_API(include_snort)
    if send_upload
      upload_API(rebuild_gems)
    end
  rescue Exception => e
    puts e.message
  end
end





