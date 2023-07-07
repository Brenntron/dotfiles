class Umbrella::Scan

  TEST_URL = "www.google.com"

  def self.new_request(address)
    request = HTTPI::Request.new(Rails.configuration.umbrella.url)
    request.ssl = true
    request.auth.ssl.verify_mode = :peer
    request.headers['Authorization'] = "Bearer #{Rails.configuration.umbrella.api_key}"
    request.headers['Content-Type'] = 'application/json'
    request.body = [ address ].to_json
    request
  end

  def self.scan_result(address:)
    request = new_request(address)



    service_status_data = {}

    response = nil

    (0..2).each do
      response = HTTPI.post(request)
      if response.code.to_i < 300
        break
      end
      sleep(2)
    end

    if response.code >= 300
      service_status_data[:type] = "outage"
      service_status_data[:exception] = "#{Rails.configuration.umbrella.url} not loading or responding"
      service_status_data[:exception_details] = response.error rescue response.body

      service_status.log(service_status_data)
    else
      service_status_data[:type] = "working"
      service_status.log(service_status_data)
    end


    response
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
        result = scan_result(address: TEST_URL)
        if result.code == 200
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
