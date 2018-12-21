class Beaker::Calculate < Beaker::Base

  def self.calculate(url, raw = false)
    is_ip_address = !!(url =~ Resolv::IPv4::Regex)
    if is_ip_address
      call_beaker_request(:get, "/calculate&ip=#{url}", {}, raw)
    else
      call_beaker_request(:get, "/calculate&url=#{url}", {}, raw)
    end
  end

end
