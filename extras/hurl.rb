#!/usr/bin/env ruby

require 'fileutils'
require 'digest'
require 'pry'


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


class HurlArgs
  attr_reader :source_arg, :project, :build_base, :output_tar_path, :env, :version, :user, :host
  attr_reader :do_vendor_bundle, :do_precompile_assets, :do_upload, :do_disgorge

  def self.usage
    puts "USAGE: ruby extras/hurl.rb [options] [tarfile | branch | tag]"
    puts "This script deploys all the content in the API directory and the UI directory up to the server"
    puts
    puts "Examples:"
    puts "    ruby extras/hurl.rb --deployment --version=analyst-console-1.0.0 v1.0.0"
    puts "    ruby extras/hurl.rb --development"
    puts "============"
    puts "Valid flags are"
    puts "--help             this message"
    puts "--deployment       build tar file for deployment"
    puts "--development      build tar file for development and install it on the test/dev host"
    puts "--notify-app       build analyst-console-notify instead of analyst-console"
    puts "--no-build         skip building new tar file, use exisiting one"
    puts "--assets           precompile assets"
    puts "--vendor-bundle    bundle install --deployment to tar vendor/bundle directory"
    puts "--no-upload        app will be built but they will be prevented from being sent to the server"
    puts "--no-disgorge      app will not be expanded on the server"
    puts "--version=<ver>    use ver as VERSION, for name of disgorged tar file"
    puts "--user=<usr>       use the specified user directory to build AC"
    puts "--host=<host>    use the specified server host to upload the build"
    exit
  end

  def set_defaults
    @env                    = nil
    @project                = 'analyst-console-escalations'
    @build_base             = '../releases'
    @get_source             = true
    @do_create_tar          = true
    @do_vendor_bundle       = false
    @do_precompile_assets   = false
    @do_upload              = true
    @do_disgorge            = true
    @bundler_version        = '_1.16.1_'
    @user                   = `whoami`.chomp
    @host                   = 'rulesuitest'
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
          @do_precompile_assets  = true
        when "--no-upload"
          @do_upload = false
        when "--no-disgorge"
          @do_disgorge = false
        when "--notify-app"
          @project = "analyst-console-notify"
        when "--deployment"
          @env                = 'deployment.env'
          @get_source         = true
          @do_vendor_bundle   = false
          @do_precompile_assets  = false
          @do_create_tar      = true
          # @bundler_version    = '_1.15.1_'
          @bundler_version    = '_1.16.1_'
        when "--development"
          @env                = 'development.env'
          @get_source         = true
          @do_vendor_bundle   = false
          @do_precompile_assets  = false
          @do_create_tar      = true
          # @bundler_version    = '_1.15.1_'
          @bundler_version    = '_1.16.1_'
        when /\A--version=(?<version>.*)\z/
          /\A--version=(?<version>.*)\z/ =~ arg
          @version = version
        when /\A--user=(?<user>.*)\z/
          /\A--user=(?<user>.*)\z/ =~ arg
          @user = user
        when /\A--host=(?<host>.*)\z/
          /\A--host=(?<host>.*)\z/ =~ arg
          @host = host
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
    if @user.nil?
      puts "No user specified using --user . Please provide a username to build the project"
      exit
    end
  end

  def rebuild?
    do_precompile_assets || do_vendor_bundle
  end

  # Figure out the name of the current local branch
  def current_git_branch
    `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
  end

  def source_arg
    @args_pos[0]
  end

  def git_label
    source_arg || current_git_branch
  end

  def input_tar?
    case
      when source_arg.nil?
        false
      when File.exist?(source_arg)
        true
      else
        false
    end
  end

  def input_tar_path
    if input_tar?
      source_arg
    else
      nil
    end
  end

  def base_dir
    @base_dir ||=
        case
          when input_tar?
            File.basename(source_arg.sub(/.gz$/, '').sub(/.tar$/, ''))
          else
            git_label
        end
  end

  def user_dir
    "/usr/local/AC-TESTING/#{@user}"
  end

  def build_path
    @build_path ||= File.join(build_base, base_dir)
  end

  def scp_dir
    "disgorge"
  end

  def release_base
    "#{user_dir}/disgorge"
  end

  def relative_dir
    "#{user_dir}/disgorge/releases"
  end

  def disgorge_tar_path
    "#{user_dir}/#{scp_dir}/releases/#{base_dir}.tar.gz"
  end

  def gen_output_tar_path
    "#{build_base}/#{base_dir}.tar.gz"
  end

  def host
    @host
  end

end


class Hurl
  attr_reader :args

  def initialize(args)
    @args = HurlArgs.new(args)
  end

  def untar(input_tar_path, build_base:, build_path:)
    puts "* untarring #{input_tar_path}"
    FileUtils.mkdir(build_base) unless File.directory?(build_base)
    FileUtils.rmtree(build_path) if File.directory?(build_path)
    puts "tar -C #{build_base} -xf #{input_tar_path}"
    system "tar -C #{build_base} -xf #{input_tar_path}"
  end

  def clone_git(git_label, project:, build_base:, build_path:)
    puts "* checkout #{git_label}"
    FileUtils.mkdir(build_base) unless File.directory?(build_base)
    FileUtils.rmtree(build_path) if File.directory?(build_path)
    system "git clone https://git.vrt.sourcefire.com/talosweb/#{project}.git -b #{git_label} --single-branch #{build_path}"
  end

  def create_tar(args, build_base:, build_path:, base_dir:)
    unless File.directory?(build_path)
      raise("Production folder doesnt exist. Probably couldn't clone it from git. Did you upload your branch to git?")
    end

    if args.do_vendor_bundle
      puts "* package the gems into vendor/cache"
      system "cd #{build_path}; rm Gemfile.lock; bundle #{@bundler_version} install --without development test"
      system "cd #{build_path} && bundle #{@bundler_version} package --frozen --all"

      system "cd #{build_path} && bundle install --deployment --without development test"
    end

    if args.do_precompile_assets
      puts "* compile assets"
      system "cd #{build_path};bundle exec rake assets:precompile"
    end

    puts "* tar up the contents of the production folder #{build_base}/#{base_dir}.tar.gz"
    system "cd #{build_base} && tar -zcf #{base_dir}.tar.gz #{base_dir}"
    "#{build_base}/#{base_dir}.tar.gz"
  end

  def rebuild(args)
    if args.input_tar?
      untar(args.input_tar_path, build_base: args.build_base, build_path: args.build_path)
    else
      clone_git(args.git_label, project: args.project, build_base: args.build_base, build_path: args.build_path)
    end
    create_tar(args,
               build_base: args.build_base,
               build_path: args.build_path,
               base_dir: args.base_dir)
  end

  def hurl(tar_path, relative_dir: args.relative_dir)
    puts "* hurling tar to remote system."
    puts "scp #{tar_path} #{@args.host}.vrt.sourcefire.com:#{relative_dir}"
    system "scp #{tar_path} #{@args.host}.vrt.sourcefire.com:#{relative_dir}"
  end

  def disgorge_cmd
    disgorge = "#{'VERSION=' + args.version + ' ' if args.version}#{args.release_base}/disgorge.sh #{args.disgorge_tar_path}"
    if args.env
      ". #{args.release_base}/#{args.env} && #{disgorge}"
    else
      disgorge
    end
  end

  def disgorge(args)
    puts disgorge_cmd
    system "ssh #{@args.host}.vrt.sourcefire.com '#{disgorge_cmd}'"
  end

  def run
    if args.rebuild?
      output_tar_path = rebuild(args)
    else
      if args.input_tar?
        output_tar_path = args.input_tar_path
      else
        output_tar_path = args.gen_output_tar_path
        puts "curl -Lku #{@args.user} https://git.vrt.sourcefire.com/talosweb/#{args.project}/tarball/#{args.base_dir} > #{output_tar_path}"
        system "curl -Lku #{@args.user} https://git.vrt.sourcefire.com/talosweb/#{args.project}/tarball/#{args.base_dir} > #{output_tar_path}"
      end
    end

    hurl(output_tar_path)               if args.do_upload
    disgorge(args)                      if args.do_disgorge
  end
end


hurl = Hurl.new(ARGV)
hurl.run
