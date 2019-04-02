# Mixin for generic web service requester for web service APIs that we call.
module ApiRequester::ApiRequester

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
    attr_reader :request_config

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

    def api_requester_config(struct)
      @request_config = struct
    end

    def self.stringkey_params(conditions = {})
      conditions.inject({}) do |params, (key, value)|
        params[key.to_s] = value if value
        params
      end
    end

    def query_string(query)
      stringkey_params(query).map {|key, value| "#{key}=#{value}"}.join('&')
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

    def uri(path, query = nil)
      raise 'Path required' unless path.present?

      slash_path = '/' == path[0] ? path : '/' + path

      "#{scheme}://#{host}:#{port}#{slash_path}#{'?' + query_string(query) if query}"
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def request_config
    @request_config ||= self.class.request_config
  end
end
