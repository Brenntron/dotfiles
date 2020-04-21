class Xbrs::GetXbrs < Xbrs::Base

  TEST_URL="www.test.com"

  def self.load_from_prefetch(data)
    response_body = JSON.parse(data)
    response_body
  end

  def self.all
    call_xbrs_request(:get, "/v1/rules", body: {})
  end

  def self.by_domain(name, raw = false)
    name = CGI.escape(name)
    call_xbrs_request(:get, "/v1/domain/#{name}", {}, raw )
  end

  def self.by_mnemonic(name, raw = false)
    call_xbrs_request(:get, "/v1/rules/#{name}", {}, raw)
  end

  def self.by_ip4(name, raw = false)
    call_xbrs_request(:get, "/v1/ip/#{name}", {}, raw)
  end

  def self.system_stats
    call_xbrs_request(:get, "/v1/status", body: {})
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
        result = by_domain(TEST_URL)
        if result.first["api"].present?
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
