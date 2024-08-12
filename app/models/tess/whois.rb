require 'service-tess-internal_services_pb'

class Tess::Whois

  TEST_DOMAIN = 'google.com'

  def self.hostport
    @hostport ||= "#{Rails.configuration.tess.host}:#{Rails.configuration.tess.port || 80}"
  end

  def self.ca_cert
    @ca_cert ||=
      if Rails.configuration.tess.ca_cert_file.present?
        File.open(Rails.configuration.tess.ca_cert_file).read
      else
        ''
      end
  end

  def self.cert
    @cert ||=
      if Rails.configuration.app_info.client_cert_file.present?
        File.open(Rails.configuration.app_info.client_cert_file).read
      else
        ''
      end
  end

  def self.cert_key
    @cert_key ||=
      if Rails.configuration.app_info.pkey_file.present?
        File.open(Rails.configuration.app_info.pkey_file).read
      else
        ''
      end
  end

  def self.creds
    if ca_cert.present? && cert_key.present?
      @creds ||= GRPC::Core::ChannelCredentials.new(ca_cert, cert_key, cert)
    else
      :this_channel_is_insecure
    end
  end

  def self.get_app_info
    Talos::AppInfo.new(
      device_id: Rails.configuration.app_info.device_id,
      product_family: Rails.configuration.app_info.product_family,
      product_id: Rails.configuration.app_info.product_id,
      product_version: Rails.configuration.app_info.product_version
    )
  end

  def self.remote_stub
    @remote_stub ||= Talos::Internal::Service::TESS::Stub.new(hostport, creds)
  end

  def self.whois_query(name)
    whois_search_request = Talos::Internal::TESS::WhoisSearchRequest.new(app_info: get_app_info, search_string: name)
    response = remote_stub.whois_query(whois_search_request)

    unless :WHOIS_SUCCESS == response.status
      message = "Failure getting whois information for #{name} -- #{response.status_message}"
      Rails.logger.error(message)
      raise message
    end

    response.result
  end

  def self.health_check
    health_report = {}

    times_to_try = 3
    times_tried = 0
    times_successful = 0
    times_failed = 0
    is_healthy = false

    (1..times_to_try).each do |i|
      begin

        result = whois_query(TEST_DOMAIN)

        if result.present?
          times_successful += 1
        else
          times_failed += 1
        end
        times_tried += 1
      rescue
        times_failed += 1
        times_tried += 1
      end

    end

    if times_successful > times_failed
      is_healthy = true
    end

    health_report[:times_tried] = times_tried
    health_report[:times_successful] = times_successful
    health_report[:times_failed] = times_failed
    health_report[:is_healthy] = is_healthy

    health_report
  end
end

