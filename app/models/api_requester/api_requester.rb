# Mixin for generic web service requester for web service APIs that we call.
#
# == Usage ==
#
# Include this mixin into your class and call any set methods you need.
# Example:
#
#     class Wbrs::Base
#       include ApiRequester::ApiRequester
#
#       set_api_requester_config Rails.configuration.wbrs
#       set_default_request_type :json
#       set_default_headers "Authorization" => "Bearer #{Rails.configuration.wbrs.auth_token}"
#     end
#
#
# == WARNING ==
# NOTICE: DANGEROUS ASSUMPTION WAS USED
#
# The intention of this mixin was that it could be added to a base class
# to make that class and all classes which inherit from it web service enabled.
# (It could just be mixed into a class, which would work too, but it should also work with inheritance.)
#
# In order to get it to work with inheritance, there must be an `inherited` method
# to extend the class methods in this mixin to the subclass.  (Damn it Matz!)
#
# I added such a method in this mixin's class methods.
# However the gotcha is that if a class using this mixin (including the subclasses)
# defines its own `inherited` method it will clobber this mixin's `inherited` method.
# So warning, if defining an `inherited` method, call the pass_on_api_requester method.
#
module ApiRequester::ApiRequester

  class ApiRequesterError < StandardError
  end

  class ApiRequesterNotFoundError < ApiRequesterError
  end

  class ApiRequesterNotAuthorized < ApiRequesterError
  end

  # Convenience method for reading config.
  # Reads standard settings, such as host, verify_mode, and ca_cert_file
  # @param [Hash] hash input from a section of config.yml
  # @return [OpenStruct] an open struct with standard values set, which can be added to for custom settings.
  def self.config_of(hash)
    struct = OpenStruct.new
    %w{host verify_mode port gssnegotiate ca_cert_file api_key}.each do |key|
      struct.send((key + '=').to_sym, hash[key])
    end

    struct.tls =
        case struct.verify_mode
        when 'no-tls', 'no-ssl'
          false
        else
          true
        end

    struct.port ||= struct.tls ? 443 : 80

    struct
  end

  module ClassMethods
    attr_reader :default_headers

    # Sets the configuration.
    #
    # This can (and should) be a configuration read from config.yml using the provided config_of method.
    #
    # @param [OpenStruct] struct The config returned from the config_of method.
    def set_api_requester_config(struct)
      @request_config = struct
    end

    def request_config
      @request_config
    end

    # Sets any headers which should be included with every API call.
    #
    # @param [Hash] headers HTTP request headers as a hash using string keys and string values
    def set_default_headers(headers)
      @default_headers ||= {}
      headers.each_pair do |key, value|
        @default_headers[key] = value
      end
    end

    def default_request_type=(default_request_type)
      @default_request_type = default_request_type
    end

    # Sets a default content type.
    #
    # This will include the appropriate content type header with every API call.
    #
    # @param [Symbol] default_request_type
    #     :json to use the input to the request as JSON for the body of the request
    #     :query_string to use the input as a query string in the URL
    #     :query_body to use the input as a query string in the http request body
    def set_default_request_type(default_request_type)
      @default_request_type = default_request_type
    end

    def default_request_type
      @default_request_type || :json
    end

    def tls?
      request_config.tls
    end

    def ssl?
      tls?
    end

    def scheme
      tls? ? 'https' : 'http'
    end

    def verify_mode
      request_config.verify_mode
    end

    def gssnegotiate?
      request_config.gssnegotiate
    end

    def ca_cert_file
      request_config.ca_cert_file
    end

    def host
      request_config.host
    end

    def port
      request_config.port
    end

    def api_key
      request_config.api_key
    end

    def stringkey_params(conditions = {})
      conditions.inject({}) do |params, (key, value)|
        params[key.to_s] = value if value
        params
      end
    end

    def query_string(query)
      stringkey_params(query).map {|key, value| "#{key}=#{value}"}.join('&')
    end

    def uri(path, query = nil)
      raise 'Path required' unless path.present?

      slash_path = '/' == path[0] ? path : '/' + path

      "#{scheme}://#{host}:#{port}#{slash_path}#{'?' + query_string(query) if query}"
    end

    def new_request(path, query = nil)

      request = HTTPI::Request.new(uri(path, query))

      case verify_mode
      when 'verify-peer'
        request.ssl = true
        request.auth.ssl.verify_mode = :peer
        request.auth.ssl.ca_cert_file = ca_cert_file if ca_cert_file
      when 'verify-none'
        request.ssl = true
        request.auth.ssl.verify_mode = :none
      else #no-tls, no-ssl
        request.ssl = false
        # request.auth.ssl.verify_mode = :none
      end

      request
    end

    def new_json_request(path, body:, headers: {})
      request = new_request(path)
      request.headers = default_headers.merge(headers).merge("Content-Type" => "application/json")
      request.body = body ? body.to_json : ''
      request
    end

    def new_query_string_request(path, query:, headers: {})
      request = new_request(path, query)
      request.headers = default_headers.merge(headers)
      request.body = ''
      request
    end

    def new_query_body_request(path, query:, headers: {})
      request = new_request(path)
      request.headers = default_headers.merge(headers).merge("Content-Type" => "application/x-www-form-urlencoded")
      request.body = query_string(query)
      request
    end

    def call_by_method(method, request)
      HTTPI.send(method, request, :curb)
    end

    def error_body(response)
      body = JSON.parse(response.body)
      body['Error']
    rescue
      nil
    end

    def request_error_handling(response)
      case
      when 300 > response.code
        response
      when 401 == response.code
        raise ApiRequesterNotAuthorized, "HTTP response #{response.code} #{error_body(response)}"
      when 404 == response.code
        raise ApiRequesterNotFoundError, "HTTP response #{response.code} #{error_body(response)}"
      else
        raise ApiRequesterError, "HTTP response #{response.code} #{error_body(response)}"
      end
    end

    def call_request(method = :get, path, request_type: default_request_type, input:, headers: {})
      request =
          case request_type
          when :json
            new_json_request(path, body: input, headers: headers)
          when :query_string
            new_query_string_request(path, query: input, headers: headers)
          when :query_body
            new_query_body_request(path, query: input, headers: headers)
          else
            raise 'Unknown request type, must be :json, :query_string, or :query_body'
          end

      request_error_handling(call_by_method(method, request))
    end

    def call_request_parsed(method = :get, path, request_type: default_request_type, input: nil, headers: {})
      response = call_request(method, path, request_type: request_type, input: input, headers: headers)
      JSON.parse(response.body)
    end

    def pass_on_api_requester(base)
      base.extend(ClassMethods)
      base.set_api_requester_config request_config
      base.set_default_request_type default_request_type
      base.set_default_headers default_headers
    end

    def inherited(subclass)
      pass_on_api_requester(subclass)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def request_config
    @request_config ||= self.class.request_config
  end
end
