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
  system "git clone https://git.vrt.sourcefire.com/talosweb/Analyst-Console.git -b #{current_git_branch} --single-branch ../production"

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
      puts "build the gems into Analyst-Console/vendor/bundle"
      system 'bundle install --deployment'
      system 'bundle package'
      system 'bundle install --standalone'
      puts "copying gems from Analyst-Console/vendor/bundle to production"
      `cp -r vendor/bundle ../production/vendor`
      `cp -r vendor/cache ../production/vendor`
    end
    puts "copying libv8 to cache folder this is needed on the server"
    `cp vendor/gems/libv8/libv8-3.16.14.17-amd64-freebsd-10.gem vendor/cache`
  else
    raise("Production folder doesnt exist. Probably couldn't clone it from git. Did you upload your branch to git?")
  end

  if (include_snort)
    `cp -r extras/snort ../production/extras`
  end

  puts "compile assets"
  Dir.chdir "../production"
  system 'bundle exec rake assets:precompile'
  Dir.chdir "../Analyst-Console"



  puts "tar up the contents of the production folder"
  system 'cd ../production/ && tar -zcvf ../rulesuitest.tar.gz . && cd ..'
end

def self.upload_API
  begin
    puts "create a new folder on the server with a new timestamp"
    timestamp = Time.now.to_i
    if File.exists?("../rulesuitest.tar.gz")
      system "ssh talosweb@rulesuitest.vrt.sourcefire.com mkdir /usr/local/www/rulesuitest/releases/#{timestamp}"
      puts "scp the tarball to rulesuitest.vrt.sourcefire.com:rulesuitest/releases/#{timestamp} folder"
      system "scp ../rulesuitest.tar.gz rulesuitest.vrt.sourcefire.com:/usr/local/www/rulesuitest/releases/#{timestamp}/"
      puts "unload the zip file into timestamp folder"
      system "ssh talosweb@rulesuitest.vrt.sourcefire.com tar -C /usr/local/www/rulesuitest/releases/#{timestamp}/ -zxvf /usr/local/www/rulesuitest/releases/#{timestamp}/rulesuitest.tar.gz"
    else
      raise("Please build the project first")
    end
  end
  timestamp
end

def self.run_server_config(timestamp, rebuild_gems)
   `ssh rulesuitest.vrt.sourcefire.com  ruby /usr/local/www/rulesuitest/releases/#{timestamp}/deploy_api.rb --no-api #{rebuild_gems} --run-config #{timestamp}`
end

def self.production_config(timestamp, rebuild_gems)
  Dir.chdir "/usr/local/www/rulesuitest/releases/#{timestamp}"
  `echo 'copy the app config and the database yaml files to the #{timestamp} folder'`
  system "rm #{Dir.pwd}/.env"
  system "rm #{Dir.pwd}/config/database.yml"
  system "rm #{Dir.pwd}/config/app_config.yml"
  system "rm #{Dir.pwd}/config/secrets.yml"
  system "rm #{Dir.pwd}/extras/ssh/ca.pem"
  system "ln -s /usr/local/www/rulesuitest/releases/shared/.env #{Dir.pwd}/.env"
  system "ln -s /usr/local/www/rulesuitest/releases/shared/secrets.yml #{Dir.pwd}/config/secrets.yml"
  system "ln -s /usr/local/www/rulesuitest/releases/shared/database.yml #{Dir.pwd}/config/database.yml"
  system "ln -s /usr/local/www/rulesuitest/releases/shared/app_config.yml #{Dir.pwd}/config/app_config.yml"
  system "ln -s /usr/local/www/rulesuitest/releases/shared/ssh/ca.pem #{Dir.pwd}/extras/ssh/ca.pem"

  `echo 'simlink the timestamped folder to the app directory'`
  system "rm /usr/local/www/rulesuitest/public/current"
  system "ln -s /usr/local/www/rulesuitest/releases/#{timestamp} /usr/local/www/rulesuitest/public/current"
  # system "rm /usr/local/www/rulesuitest/public/app"
  #so we are gonna have to copy it instead
  # system "rsync -r #{Dir.pwd}/* /usr/local/www/rulesuitest"


  `echo 'build the gems locally if folder exists'`
  # if vendor folder doesnt exist or we ask to rebuild the gems then build the gems and create a copy for later
  if !File.directory?("/usr/local/www/rulesuitest/releases/shared/vendor") || rebuild_gems
    `echo 'rebuilding gems and over writing the ones in shared vendor'`
    system "bundle install --deployment"
    system "rm -rf /usr/local/www/rulesuitest/releases/shared/vendor"
    system "cp -r #{Dir.pwd}/vendor /usr/local/www/rulesuitest/releases/shared/"
  else
    `echo 'dont rebuild gems and copy shared/vendor to app/vendor'`
    system "rm -rf #{Dir.pwd}/vendor"
    system "cp -r /usr/local/www/rulesuitest/releases/shared/vendor #{Dir.pwd}/vendor"
    system "bundle install --deployment --without development test"
  end

  `echo 'Restarting server tmp/restart.txt'`
  system "mkdir #{Dir.pwd}/tmp"
  system "touch tmp/restart.txt"

  `echo 'removing rulesuitest.tar.gz'`
  system "rm #{Dir.pwd}/rulesuitest.tar.gz"
end

process_api = true
build_api = true
send_upload = true
rebuild_gems = false
include_snort = true
run_config = false
timestamp = 0

ARGV.each do |a|
  case a
    when "--run-config"
      timestamp = ARGV[ARGV.index(a)+1].to_i
      puts "timestamp is: #{timestamp}"
      if timestamp.is_a? Numeric
        run_config = true
        process_api = false
      else
        puts "One of your flags '#{a}' requires a timestamp."
        run_config = false
        process_api = false
        break
      end
    when "--no-build"
      build_api = false
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
    when timestamp
      puts "processing time stamp"
    else
      puts "One of your flags '#{a}' is not valid. Try again. use -h or --help"
      process_api = false
      send_upload = false
      break
  end
end


if process_api
  begin
    if build_api
      build_API(include_snort)
    end
    if send_upload
      timestamp = upload_API
      if rebuild_gems
        run_server_config(timestamp, "--rebuild-gems")
      else
        run_server_config(timestamp, "")
      end
    end

  rescue Exception => e
    puts e.message
  end
end
if run_config
  begin
      production_config(timestamp,rebuild_gems)
  rescue Exception => e
    puts e.message
  end
end





