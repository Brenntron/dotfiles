# core
require 'base64'
require 'net/http'

# gems
# require 'gssapi'
require 'httpi'
require 'curb'
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
                   basic_auth: nil, tls_mode: nil, ssl_mode: 'no-ssl', ca_file: nil, verbose: false, gssapi: false)
      @channel    = channel
      @sender     = sender
      @addressee  = addressee

      @host       = host || self.class.default_host
      @port       = port || self.class.default_port
      @uri_base   = uri_base
      @gssapi     = gssapi
      @extras     = extras || {}


      @basic_auth = basic_auth

      raise 'Cannot determine host' unless @host
      raise 'Cannot determine port' unless @port

      @http = HTTPI::Request.new
      case tls_mode || ssl_mode
        when 'verify-peer'
          @protocol = "https"
          @use_ssl = true
          @http.auth.ssl.verify_mode = :peer
          @http.auth.ssl.ca_cert_file = ca_file #this will be nil for Heroku apps
        when 'verify-none'
          @protocol = "https"
          @use_ssl = true
          @http.auth.ssl.verify_mode = :none
        else
          @protocol = "http"
          @use_ssl = false
      end
      if @gssapi
        @http.auth.gssnegotiate
      end
      @http.url = url
    end

    def uri
      @uri ||= "#{uri_base}/#{channel}/messages"
    end

    def url
      @url ||= "#{@protocol}://#{@host}:#{@port}#{uri}"
    end

    def post(message:)
      if @http.auth.basic?
        @http.auth.basic(@basic_auth[:user], @basic_auth[:password])
      end
      @http.body = {envelope: {channel: channel, sender: sender, addressee: addressee}, message: message}.merge(@extras).to_json
      @http.headers = {"Content-Type":"application/json" }
      HTTPI.post(@http, :curb)
    end
  end
end

