class CloudIntel::ReputationHit
  # Gets mnemonics of multiple IP addresses
  #
  # example:
  #   ReputiationHit.ip_mnemonics(["2.3.4.5", "35.236.52.109"])
  #   => { "2.3.4.5" => {mnemonics: ['Pbl']},
  #        "35.236.52.109" => {mnemonics: ['abc', 'def']}}
  #
  # @param [Array<String>] ips the IP addresses, e.g. ["2.3.4.5", "35.236.52.109"]
  # @return [Hash] keys are inputted IP addresses, values are hash with array of mnemonics
  def self.ip_mnemonics(ips)
    byebug
    reply = Beaker::Ipd.query_reputation(ips)
    byebug
    reply
  end
end
