class Beaker::Verdicts < Beaker::Base

  def self.verdicts(domains, raw = false)
      beaker_response = []
      domains.each_slice(500) do |batch|
          beaker_response += call_beaker_request(:post, "/verdicts", batch, raw)
      end

    beaker_response
  end

end
