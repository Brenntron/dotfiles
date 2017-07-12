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
  attr_reader :project, :build_base, :output_tar_path

  def self.usage
    puts "USAGE: ruby extras/hurl.rb [options] [tarfile | branch | tag]"
    puts "This script deploys all the content in the API directory and the UI directory up to the server"
    puts "============"
    puts "Valid flags are"
    puts "--help             this message"
    puts "--deployment       build tar file for deployment"
    puts "--development      build tar file for development and install it on the test/dev host"
    puts "--no-build         skip building new tar file, use exisiting one"
    puts "--assets           precompile assets"
    puts "--vendor-bundle    bundle install --deployment to tar vendor/bundle directory"
    puts "--no-upload        app will be built but they will be prevented from being sent to the server"
    puts "--no-disgorge      app will not be expanded on the server"
    exit
  end

  def set_defaults
    @env                = nil
    @project            = 'analyst-console'
    @build_base         = '../releases'
    @get_source         = true
    @do_create_tar      = true
    @do_vendor_bundle   = false
    @precompile_assets  = false
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

  def rebuild?
    precompile_assets? || vendor_bundle?
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
    @args_pos[0]
  end

  def git_label
    source_arg || current_git_branch
  end

  def use_tar?
    source_arg && File.exist?(source_arg)
  end

  def input_tar_path
    @in_tar_path ||= (use_tar? ? source_arg : nil)
  end

  def tag_dir
    @tag_dir ||=
        case
          when use_tar?
            File.basename(source_arg.sub(/.gz$/, '').sub(/.tar$/, ''))
          else
            git_label
        end
  end

  def tar_filename
    @tar_filename = "#{tag_dir}.tar.gz"
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

  def untar(input_tar_path, build_base_given = build_base)
    puts "* untarring #{input_tar_path}"
    FileUtils.mkdir(build_base_given) unless File.directory?(build_base_given)
    FileUtils.rmtree(build_path) if File.directory?(build_path)
    puts "tar -C #{build_base_given} -xf #{input_tar_path}"
    system "tar -C #{build_base_given} -xf #{input_tar_path}"
  end

  def clone(git_label_given, build_base_given = build_base)
    puts "* checkout #{git_label_given}"
    FileUtils.mkdir(build_base_given) unless File.directory?(build_base_given)
    FileUtils.rmtree(build_path) if File.directory?(build_path)
    system "git clone https://git.vrt.sourcefire.com/talosweb/analyst-console.git -b #{git_label_given} --single-branch #{build_path}"
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
      system "cd #{build_path} && bundle install --deployment --without development test"
    end

    puts "* tar up the contents of the production folder #{build_base}/#{tag_dir}.tar.gz"
    system "cd #{build_base} && tar -zcf #{tag_dir}.tar.gz #{tag_dir}"
    tag_dir
  end

  def hurl(tar_path)
    puts "* hurling tar to remote system."
    system "scp #{tar_path} rulesuitest.vrt.sourcefire.com:#{scp_path(tag_dir)}"
  end

  def disgorge
    if @env
      system "ssh rulesuitest.vrt.sourcefire.com '. #{release_base}/#{@env} && #{release_base}/disgorge.sh #{tar_path(tag_dir)}'"
    else
      system "ssh rulesuitest.vrt.sourcefire.com '#{release_base}/disgorge.sh #{tar_path(tag_dir)}'"
    end
  end

  def run
    if rebuild?
      untar(input_tar_path)             if input_tar_path
      clone(git_label)                  unless input_tar_path
      @output_tar_path = create_tar
    else
      if input_tar_path
        @output_tar_path = input_tar_path
      else
        @output_tar_path = "#{build_base}/#{tag_dir}.tar.gz"
        system "curl -L https://git.vrt.sourcefire.com/talosweb/#{project}/tarball/#{tag_dir} > #{output_tar_path}"
      end
    end

    hurl(@output_tar_path)              if @do_upload
    disgorge                            if @do_disgorge

  rescue Exception => e
    puts e.message
  end
end


hurl = Hurl.new(ARGV)
hurl.run

