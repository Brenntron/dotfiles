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

  def self.usage
    puts "USAGE: ruby extras/hurl.rb [options] [tarfile | branch | tag]"
    puts "This script deploys all the content in the API directory and the UI directory up to the server"
    puts "============"
    puts "Valid flags are"
    puts "--help             this message"
    puts "--deployment       build tar file for deployment"
    puts "--development      build tar file for development and install it on the test/dev host"
    puts "--no-build         skip building new tar file, use exisiting one"
    puts "--[no-]assets      [skip] precompile assets"
    puts "--vendor-bundle    bundle install --deployment to tar vendor/bundle directory"
    puts "--no-upload        app will be built but they will be prevented from being sent to the server"
    puts "--no-disgorge      app will not be expanded on the server"
    exit
  end

  def set_defaults
    @env                = nil
    @build_base         = '../releases'
    @get_source         = true
    @do_create_tar      = true
    @do_vendor_bundle   = false
    @precompile_assets  = true
    @do_upload          = true
    @do_disgorge        = true
    # @bundler_version    = '_1.12.5_'
    @bundler_version    = '_1.14.6_'
  end

  def scan_args(args)
    args.inject([]) do |pos_args, arg|
      case arg
        when "-h", "--help"
          self.class.usage
        when "--no-build"
          @get_source         = false
          @do_create_tar      = false
        when "--vendor-bundle"
          @do_vendor_bundle   = true
        when "--assets"
          @precompile_assets  = true
        when "--no-assets"
          @precompile_assets  = false
        when "--no-upload"
          @do_upload = false
        when "--no-disgorge"
          @do_disgorge = false
        when "--deployment"
          @env                = 'deployment.env'
          @get_source         = true
          @do_vendor_bundle   = false
          @precompile_assets  = false
          @do_create_tar      = true
          # @bundler_version    = '_1.15.1_'
          @bundler_version    = '_1.14.6_'
        when "--development"
          @env                = 'development.env'
          @get_source         = true
          @do_vendor_bundle   = false
          @precompile_assets  = false
          @do_create_tar      = true
          # @bundler_version    = '_1.15.1_'
          @bundler_version    = '_1.14.6_'
        when /\A-/
          puts "One of your flags '#{arg}' is not valid. Ignored, use -h or --help"
          self.class.usage
        when /\A_.*_\z/
          @bundler_version    = arg
        else
          pos_args << arg
      end
      pos_args
    end
  end

  def initialize(args)
    @args = args
    set_defaults
    @args_pos = scan_args(args)
  end

  def precompile_assets?
    @precompile_assets
  end

  def vendor_bundle?
    @do_vendor_bundle
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
    if File.directory?(build_base)
      FileUtils.rmtree(build_base)
    end
    FileUtils.mkdir(build_base)
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

  def create_tar
    unless File.directory?(build_path)
      raise("Production folder doesnt exist. Probably couldn't clone it from git. Did you upload your branch to git?")
    end

    puts "* package the gems into vendor/cache"
    system "cd #{build_path}; rm Gemfile.lock; bundle #{@bundler_version} install --without development test"
    system "cd #{build_path} && bundle #{@bundler_version} package --frozen --all"

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
    puts "* hurling tar to remote system."
    system "scp #{build_base}/#{tag_dir}.tar.gz rulesuitest.vrt.sourcefire.com:#{scp_path(tag_dir)}"
  end

  def disgorge
    if @env
      system "ssh rulesuitest.vrt.sourcefire.com '. #{release_base}/#{@env} && #{release_base}/disgorge.sh #{tar_path(tag_dir)}'"
    else
      system "ssh rulesuitest.vrt.sourcefire.com '#{release_base}/disgorge.sh #{tar_path(tag_dir)}'"
    end
  end

  def run
    get_source      if @get_source
    create_tar      if @do_create_tar
    hurl            if @do_upload
    disgorge        if @do_disgorge

  rescue Exception => e
    puts e.message
  end
end


hurl = Hurl.new(ARGV)
hurl.run

