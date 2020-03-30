class Virustotal::GetVirustotal < Virustotal::Base

  TEST_URL = "www.google.com"

  def self.load_from_prefetch(data)
    response_body = JSON.parse(data)
    response_body
  end

  def self.by_domain(url, raw = false)
    call_virustotal_request(:get, "/vtapi/v2/url/report?resource=#{url}", {}, raw)
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
        result = by_domain(TEST_URL, false)
        if result["scan_id"].present?
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
