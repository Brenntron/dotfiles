# core
require 'base64'
require 'net/http'

# gems
# require 'gssapi'
require 'openssl'
require 'json'

module PeakeBridge
  class BasicPeakeBridge
    attr_reader :host, :port, :uri_base, :channel, :sender, :addressee, :extras, :basic_auth

    class << self
      attr_accessor :default_host, :default_port
    end

    # Initializes this object as a connection to a peake-bridge message reciever.
    #
    # Messages will be delivered to all subscribers to the channel.
    #
    # @param [String] channel (envelope) The bridge message channel to use for the message.
    # @param [String] sender (envelope) String to identify yourself as the source.
    # @param [String] addressee (envelope) String to identify an intended end addressee.
    # @param [String] host TCP/IP host of next bridge hop.
    # @param [Integer] port TCP/IP port of next bridge hop.
    # @param [String] uri_base prefix of http path.  Messages posted to #{uri_base}/#{channel}/messages.
    # @param [Hash] extras hash to be merged into post, provided for API keys needed by server.
    # @param [Hash] basic_auth hash with :user and :password keys for using HTTP basic authentication.
    # @param [String] tls_mode verify-peer or verify-none for verify mode of https, and no-tls or no-ssl for http.
    # @param [String] ssl_mode use as values for tls_mode if tls_mode is nil or not given.
    # @param [String] ca_file path the PEM file of trusted certs.
    # @param [Boolean] gssapi Set to a truthy value to enable Kerberos authentication
    def initialize(channel:, sender:, addressee: nil, host: nil, port: nil, uri_base: '/channels', extras: nil,
                   basic_auth: nil, tls_mode: nil, ssl_mode: 'no-ssl', ca_file: nil,
                   gssapi: nil, gssapi_script: '/usr/local/sbin/krb_auth_token.pl')
      @channel    = channel
      @sender     = sender
      @addressee  = addressee

      @host       = host || self.class.default_host
      @port       = port || self.class.default_port
      @uri_base   = uri_base

      @extras     = extras || {}


      @basic_auth = basic_auth

      raise 'Cannot determine host' unless @host
      raise 'Cannot determine port' unless @port

      @http = Net::HTTP.new(@host, @port)
      case tls_mode || ssl_mode
        when 'verify-peer'
          @http.use_ssl = true
          @http.verify_mode = 1
        when 'verify-none'
          @http.use_ssl = true
          @http.verify_mode = 0
        else
          @http.use_ssl = false
      end

      @http.ca_file = ca_file

      if gssapi
        # gsscli = GSSAPI::Simple.new(@host, 'HTTP')
        # token = gsscli.init_context
        raise 'No gssapi script provided' unless gssapi_script
        token = `#{gssapi_script}`
        # @auth_value = "Negotiate #{Base64.strict_encode64(token)}"
        @auth_value = "Negotiate #{token}"
      end
    end

    def uri
      @uri ||= "#{uri_base}/#{channel}/messages"
    end

    def post(message:)
      request = Net::HTTP::Post.new(uri)
      request.add_field('Content-Type', 'application/json')

      request.add_field('Authorization', @auth_value)

      request.basic_auth @basic_auth[:user], @basic_auth[:password] if @basic_auth
      request.body = {envelope: {channel: channel, sender: sender, addressee: addressee}, message: message}.merge(@extras).to_json
      @http.request(request)
    end
  end
end

