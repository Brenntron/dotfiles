class CloudIntel::Whois
  def self.whois_query(name)
    Tess::Whois.whois_query(name)
  end
end
