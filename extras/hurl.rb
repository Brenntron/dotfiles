require 'fileutils'
require 'digest'


# This is an install system which, unlike deploy_api.rb, avoids using the talosweb service account.
#
# Assumptions:
# -   The disgorge system is installed on the backend to complete the install
#
# This script first collects the source code.
# It optionally will:
# -   Check out code from git using a given branch or tag name
# -   Check out code from git using the current branch
# -   Untar a given file
#
# This script will package gems, precompile assets, and re-tar file with results.
#
# The script will tar up the resulting files, scp them to the backend and call the disgorge system.
#
# The disgorge script will
# -   uncompress the tar file
# -   copy or link shared files and directories
# -   bundle install
# -   run migrations
# -   set up the subverion
# -   create a link to the new release directory


class Hurl
  attr_reader :build_base

  def scan_args(args)
    args.inject([]) do |pos_args, arg|
      case arg
        when /\A-/
          #do nothing
        when /\A_.*_\z/
          @bundler_version = arg
        else
          pos_args << arg
      end
      pos_args
    end
  end

  def initialize(args,
                 bundler_version: nil,
                 precompile_assets: true,
                 vendor_bundle: false,
                 build_base: '../releases')
    @args = args
    @bundler_version = '_1.12.5_'
    @args_pos = scan_args(args)
    @bundler_version = bundler_version if bundler_version
    @build_base = build_base
    @precompile_assets = precompile_assets
    @vendor_bundle = vendor_bundle
  end

  def precompile_assets?
    @precompile_assets
  end

  def vendor_bundle?
    @vendor_bundle
  end

  def red(str)
    "\e[31m#{str}\e[0m"
  end

  # Figure out the name of the current local branch
  def current_git_branch
    branch = `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
    puts "Deploying branch #{red branch}"
    branch
  end

  def source_arg
    @args_pos[0] || current_git_branch
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

  def scp_dir
    "disgorge"
  end

  def release_base
    "~/disgorge"
  end

  def scp_path(tag_dir)
    "#{scp_dir}/releases/#{tag_dir}.tar.gz"
  end

  def tar_path(tag_dir)
    "~/#{scp_dir}/releases/#{tag_dir}.tar.gz"
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

  def build_install_tar
    unless File.directory?(build_path)
      raise("Production folder doesnt exist. Probably couldn't clone it from git. Did you upload your branch to git?")
    end

    puts "* package the gems into vendor/cache"
    system "cd #{build_path}; rm Gemfile.lock; bundle #{@bundler_version}  install"
    system "cd #{build_path} && bundle #{@bundler_version} package --frozen --all"
    puts "* copying libv8 to cache folder this is needed on the server"
    system "cp #{build_path}/vendor/gems/libv8/libv8-3.16.14.17-amd64-freebsd-10.gem #{build_path}/vendor/cache"
    # system "cd #{build_path} && bundle #{@bundler_version} install --standalone --deployment --frozen"

    if precompile_assets?
      puts "* compile assets"
      # Dir.chdir "../production"
      system "cd #{build_path};bundle exec rake assets:precompile"
      # Dir.chdir "../analyst-console"
    end

    if vendor_bundle?
      system "cd #{build_path} && bundle install --deployment --frozen --without development test"
    end

    puts "* tar up the contents of the production folder #{build_base}/#{tag_dir}.tar.gz"
    system "cd #{build_base} && tar -zcf #{tag_dir}.tar.gz #{tag_dir}"
  end

  def hurl
    system "scp #{build_base}/#{tag_dir}.tar.gz rulesuitest.vrt.sourcefire.com:#{scp_path(tag_dir)}"
  end

  def disgorge
    system "ssh rulesuitest.vrt.sourcefire.com '. #{release_base}/disgorge.env && #{release_base}/disgorge.sh #{tar_path(tag_dir)}'"
  end

  def run(build_ac, send_upload)
    if build_ac
      get_source
      build_install_tar
    end
    if send_upload
      hurl
      disgorge
    end

  rescue Exception => e
    puts e.message
  end
end


build_ac = true
precompile_assets = true
vendor_bundle = false
send_upload = true
bundler_version = nil

ARGV.each do |arg|
  case arg
    when "--deployment"
      build_ac = true
      precompile_assets = true
      vendor_bundle = true
      send_upload = false
      bundler_version = '_1.15.1_'
    when "--no-build"
      build_ac = false
    when "--vendor-bundle"
      vendor_bundle = true
    when "--no-assets"
      precompile_assets = false
    when "--no-upload"
      send_upload = false
    when "-h", "--help"
      puts "USAGE: ruby extras/hurl.rb [options] [tarfile | branch | tag]"
      puts "This script deploys all the content in the API directory and the UI directory up to the server"
      puts "============"
      puts "Valid flags are"
      puts "--help             this message"
      puts "--deployment       build tar file for deployment"
      puts "--no-build         skip building new tar file, use exisiting one"
      puts "--no-assets        skip precompiling assets"
      puts "--vendor-bundle    bundle install --deployment to tar vendor/bundle directory"
      puts "--no-upload        apps will be built but they will be prevented from being sent to the server"
      exit
    when /\A-/
      puts "One of your flags '#{arg}' is not valid. Try again. use -h or --help"
      exit
  end
end

hurl = Hurl.new(ARGV,
                bundler_version: bundler_version,
                precompile_assets: precompile_assets,
                vendor_bundle: vendor_bundle)
hurl.run(build_ac, send_upload)

