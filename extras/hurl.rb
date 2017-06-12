require 'fileutils'
require 'digest'


def red(str)
  "\e[31m#{str}\e[0m"
end


class Hurl
  attr_reader :build_base

  def initialize(args, build_base: '../releases')
    @args = args
    @build_base = build_base
  end

  # Figure out the name of the current local branch
  def current_git_branch
    branch = `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
    puts "Deploying branch #{red branch}"
    branch
  end

  def source_arg
    @args[0] || current_git_branch
  end

  def use_tar?
    source_arg && File.exist?(source_arg)
  end

  def tag_dir
    @tag_dir ||=
        case
          when use_tar?
            File.basename(source_arg.sub(/.gz$/, '').sub(/.tar$/, ''))
          else
            source_arg
        end
  end

  def build_path
    @build_path ||= File.join(build_base, tag_dir)
  end

  def get_source
    FileUtils.mkdir(build_base) unless File.directory?(build_base)
    if use_tar?
      puts "* untaring #{source_arg}"
      puts "tar -C #{build_base} -xf #{source_arg}"
      system "tar -C #{build_base} -xf #{source_arg}"
    else
      puts "* checkout #{tag_dir}"
      FileUtils.rm_r(build_path, force: true) if File.directory?(build_path)
      system "git clone https://git.vrt.sourcefire.com/talosweb/analyst-console.git -b #{source_arg} --single-branch #{build_path}"
    end
  end
end




def self.build_api(hurl, include_snort)
  unless File.directory?(hurl.build_path)
    raise("Production folder doesnt exist. Probably couldn't clone it from git. Did you upload your branch to git?")
  end



  puts "* build the gems into vendor/bundle"
  # system 'bundle install --deployment'
  puts "cd #{hurl.build_path};bundle package --frozen --all"
  system "cd #{hurl.build_path};bundle _1.12.5_ package --frozen --all"
  puts "cd #{hurl.build_path};bundle install --standalone --deployment --frozen"
  system "cd #{hurl.build_path};bundle _1.12.5_ install --standalone --deployment --frozen"
  puts "eh, exiting"
  exit

  puts "copying gems from analyst-console/vendor/bundle to production"
  `cp -r vendor/bundle ../production/vendor`
  `cp -r vendor/cache ../production/vendor`
  puts "copying libv8 to cache folder this is needed on the server"
  `cp vendor/gems/libv8/libv8-3.16.14.17-amd64-freebsd-10.gem vendor/cache`

  if include_snort
    # `cp -r extras/snort ../production/extras`
    system "mkdir ../production/extras/snort"
    system "svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/snort-rules/ ../production/extras/snort/snort-rules/"
    system "svn co --depth files https://repo-test.vrt.sourcefire.com/svn/rules/trunk/so_rules/ ../production/extras/snort/so_rules/"
    system "rm ../production/extras/snort/so_rules/*.c ../production/extras/snort/so_rules/*.h"
  end

  puts "compile assets"
  Dir.chdir "../production"
  system 'bundle exec rake assets:precompile'
  Dir.chdir "../analyst-console"



  puts "tar up the contents of the production folder"
  system 'cd ../production/ && tar -zcvf ../analyst-console.tar.gz . && cd ..'
end

def self.upload_api
  begin
    puts "create a new folder on the server with a new timestamp"
    timestamp = Time.now.to_i
    if File.exists?("../analyst-console.tar.gz")
      system "ssh talosweb@rulesuitest.vrt.sourcefire.com mkdir /usr/local/www/analyst-console/releases/#{timestamp}"
      puts "scp the tarball to rulesuitest.vrt.sourcefire.com:analyst-console/releases/#{timestamp} folder"
      system "scp ../analyst-console.tar.gz talosweb@rulesuitest.vrt.sourcefire.com:/usr/local/www/analyst-console/releases/#{timestamp}/"
      puts "unload the zip file into timestamp folder"
      system "ssh talosweb@rulesuitest.vrt.sourcefire.com tar -C /usr/local/www/analyst-console/releases/#{timestamp}/ -zxvf /usr/local/www/analyst-console/releases/#{timestamp}/analyst-console.tar.gz"
    else
      raise("Please build the project first")
    end
  end
  timestamp
end

def self.run_server_config(timestamp, rebuild_gems)
   `ssh talosweb@rulesuitest.vrt.sourcefire.com  ruby /usr/local/www/analyst-console/releases/#{timestamp}/deploy_api.rb --no-api #{rebuild_gems} --run-config #{timestamp}`
end

def self.production_config(timestamp, rebuild_gems)
  Dir.chdir "/usr/local/www/analyst-console/releases/#{timestamp}"
  `echo 'copy the app config and the database yaml files to the #{timestamp} folder'`

  system "rm -rf log"
  system "ln -s ../shared/log ."
  system "for file in log/*; do echo ### Release #{timestamp} >> $file; done"

  system "rm ./.env"
  system "ln -s ../shared/.env ."

  system "rm -rf extras/ssh"
  system "ln -s ~/analyst-console/.ssh extras/ssh"

  `echo 'simlink the timestamped folder to the app directory'`
  system "rm ../../public/current"
  system "ln -s /usr/local/www/analyst-console/releases/#{timestamp} ../../public/current"
  # system "rm /usr/local/www/analyst-console/public/app"
  #so we are gonna have to copy it instead
  # system "rsync -r #{Dir.pwd}/* /usr/local/www/analyst-console"


  `echo 'build the gems locally if folder exists'`
  # if vendor folder doesnt exist or we ask to rebuild the gems then build the gems and create a copy for later
  if !File.directory?("/usr/local/www/analyst-console/releases/shared/vendor") || rebuild_gems
    `echo 'rebuilding gems and over writing the ones in shared vendor'`
    system "bundle install --deployment"
    system "rm -rf /usr/local/www/analyst-console/releases/shared/vendor"
    system "cp -r #{Dir.pwd}/vendor /usr/local/www/analyst-console/releases/shared/"
  else
    `echo 'dont rebuild gems and copy shared/vendor to app/vendor'`
    system "rm -rf #{Dir.pwd}/vendor"
    system "cp -r /usr/local/www/analyst-console/releases/shared/vendor #{Dir.pwd}/vendor"
    system "bundle install --deployment --without development test"
  end

  `echo 'Restarting server tmp/restart.txt'`
  system "mkdir #{Dir.pwd}/tmp"
  system "touch tmp/restart.txt"


  `echo 'removing analyst-console.tar.gz'`
  system "rm #{Dir.pwd}/analyst-console.tar.gz"
end

process_api = true
build_api = true
send_upload = true
rebuild_gems = false
include_snort = true
run_config = false
timestamp = 0

args_pos = []
ARGV.each do |arg|
  case arg
    when "--run-config"
      timestamp = ARGV[ARGV.index(arg)+1].to_i
      puts "timestamp is: #{timestamp}"
      if timestamp.is_a? Numeric
        run_config = true
        process_api = false
      else
        puts "One of your flags '#{arg}' requires a timestamp."
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
    when "-h", "--help"
      puts "USAGE: ruby extras/hurl.rb [options] [tarfile | branch | tag]"
      puts "This script deploys all the content in the API directory and the UI directory up to the server"
      puts "============"
      puts "Valid flags are"
      puts "--help             this message"
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
      if 1 <= args_pos.length
        puts "One of your flags '#{arg}' is not valid. Try again. use -h or --help"
        process_api = false
        send_upload = false
        break
      else
        args_pos << arg
      end
  end
end

if process_api
  begin
    if build_api
      hurl = Hurl.new(args_pos)
      hurl.get_source
      build_api(hurl, include_snort)
    end
    if send_upload
      timestamp = upload_api
      if rebuild_gems
        run_server_config(timestamp, "--rebuild-gems")
      else
        run_server_config(timestamp, "")
      end
    end

  rescue Exception => e
    puts e.message
  end

  if run_config
    begin
      production_config(timestamp,rebuild_gems)
    rescue Exception => e
      puts e.message
    end
  end
end

