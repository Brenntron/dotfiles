require 'service-enrich_services_pb'

class EnrichmentService::Enrich < EnrichmentService::EnrichmentServiceBase

  # Request context for a Domain. This can be used to request context for
  # either domains like "google.com" or fully qualified domain names like "mail.google.com".
  def self.query_domain(domain)
    query_domain_request = Talos::ENRICH::QueryDomainRequest.new(app_info: get_app_info, domain: domain)
    remote_stub.query_domain(query_domain_request)
  end

  # Request context for an IP, either v4 or v6. For example, the IP address
  # could either be the address a website resolves to or the source of an SMTP connection.
  def self.query_ip(ip_address)
    query_ip_request = Talos::ENRICH::QueryIPRequest.new(app_info: get_app_info, ip: get_ip_address(ip_address))
    remote_stub.query_ip(query_ip_request)
  end

  # Request context for an URL such as you'd observe in a browser.
  def self.query_url(raw_url)
    url = Talos::URL.new(raw_url: raw_url)
    query_url_request = Talos::ENRICH::QueryURLRequest.new(app_info: get_app_info, url: url)
    remote_stub.query_url(query_url_request)
  end

  # Request context for a SHA. The SHA is a fingerprint of a file that would
  # appear on a computer it has been downloaded onto.
  def self.query_sha(sha)
    query_sha_request = Talos::ENRICH::QuerySHARequest.new(app_info: get_app_info, sha: sha)
    remote_stub.query_sha(query_sha_request)
  end

  def self.remote_stub
    @remote_stub ||= Talos::Service::ENRICH::Stub.new(hostport, creds)
  end

end