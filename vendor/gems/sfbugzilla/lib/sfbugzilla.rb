#!/usr/bin/env ruby

require 'bugzilla'
require 'openssl'
require 'yaml'
require 'highline/import'
require 'digest/md5'
require 'mime/types'

BUGZILLA_COOKIE_FILE = '.ruby-bugzilla-cookie.yml'
BUGZILLA_HOST = ENV['BUGZILLA_HOST']

class XMLRPC::Client
   def fix_ssl
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
   end
end

class Bugzilla::XMLRPC
   def initialize(host, port = 443, path = '/xmlrpc.cgi')
      if host.nil?
         throw Exception.new("Please set the BUGZILLA_HOST environment variable")
      end
      
      use_ssl = (port == 443) ? true : false
      @xmlrpc = XMLRPC::Client.new(host, path, port, nil, nil, nil, nil, use_ssl, 60)
      @xmlrpc.fix_ssl
      # @xmlrpc.http_header_extra = {'accept-encoding' => 'identity'}

   end

   def bugzilla_login(user, username, password)
      user.login({'login' => username, 'password' => password, 'remember' => true})
   end

   def login(user)
      user.session(nil, nil) do
         if token.nil?
            username = ENV['BUGZILLA_USER'] || (ask("User: ") {|q| q.echo = true})
            password = ENV['BUGZILLA_PASS'] || (ask("Password: ") {|q| q.echo = false})

            begin
               user.session(username, password) {}
            rescue XMLRPC::FaultException => e
               puts e.to_s
            rescue EOFError => e
               puts "Fuck, fuck, fuck: #{e.to_s}"
            end
        end
      end
   end
end

class Bugzilla::Bug
   def _create(cmd, *args)
      requires_version(cmd, 3.4)
      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)
      @iface.call(cmd, args[0])
   end

   def _update(cmd, *args)
      requires_version(cmd, 3.4)
      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)
      @iface.call(cmd, args[0])
   end
   def _update_attachment(cmd,*args)
     requires_version(cmd, 5.0)
     raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)
     @iface.call(cmd, args[0])
   end

   def _add_attachment(cmd, *args)
      requires_version(cmd, 4.0)
      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)
      @iface.call(cmd, args[0])
   end
   
   def _add_comment(cmd, *args)
      requires_version(cmd, 4.0)
      raise ArgumentError, "Invalid parameters" unless args[0].kind_of?(Hash)
      @iface.call(cmd, args[0])
   end

   # attachments: array of attachment objects
   def fetch_attachments(attachs, output_path = '.')
      attachments(:attachment_ids => attachs.map {|a| a['id']})['attachments'].each do |a_id, attachment|
         File.open("#{output_path}/#{attachment['file_name']}", "w+") do |f|
            f.write(attachment['data'])
         end
      end
   end

   def attach_file(id, file, description = nil)
      data = File.read(file)
      mime = MIME::Type.simplified(MIME::Types.type_for(file).first.to_s)
      mime ||= 'application/octet-stream'
      description ||= "md5(#{Digest::MD5.hexdigest(data)})"

      add_attachment(
         :ids => id,
         :file_name => File.basename(file),
         :summary => File.basename(file),
         :comment => description,
         :data => XMLRPC::Base64.new(data),
         :content_type => mime
      )
   end
end
