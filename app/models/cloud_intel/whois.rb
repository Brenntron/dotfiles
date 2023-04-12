class CloudIntel::Whois
  def self.whois_query(name)
    Tess::Whois.whois_query(SimpleIDN.to_ascii(name))
  end
end
