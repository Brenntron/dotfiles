require "service-tmi-internal_services_pb"

class Tmi::TmiGrpc < Tmi::TmiBase
  # rpc :Read, ::Talos::Internal::TMI::ReadRequest, ::Talos::Internal::TMI::ReadReply
  def self.read(domain: nil, url: nil, ip: nil, sha: nil)
    if [domain, url, ip, sha].compact.length > 1
      raise Tmi::TmiError, "Only one observable can be queried at a time"
    end

    if domain.present?
      observable = ::Talos::Internal::TMI::Observable.new(domain: domain)
    elsif url.present?
      url_message = ::Talos::URL.new(raw_url: url)
      observable = ::Talos::Internal::TMI::Observable.new(url: url_message)
    elsif ip.present?
      ip_address_message = get_ip_address(ip)
      observable = ::Talos::Internal::TMI::Observable.new(ip: ip_address_message)
    elsif sha.present?
      observable = ::Talos::Internal::TMI::Observable.new(sha: sha)
    else
      raise Tmi::TmiError, "Missing observable"
    end

    read_request = ::Talos::Internal::TMI::ReadRequest.new(observation: observable)
    remote_stub.read(read_request)
  end

  # rpc :UpdateByContext, ::Talos::Internal::TMI::UpdateRequest, ::Talos::Internal::TMI::UpdateReply
  def self.update_by_context()
    update_request = ::Talos::Internal::TMI::UpdateRequest.new()
    remote_stub.update_by_context(update_request)
  end

  # rpc :UpdateByMnemonic, ::Talos::Internal::TMI::MnemonicUpdateRequest, ::Talos::Internal::TMI::UpdateReply
  def self.update_by_mnemonic()
    mnemonic_update_request = ::Talos::Internal::TMI::MnemonicUpdateRequest.new()
    remote_stub.update_by_mnemonic(mnemonic_update_request)
  end

  # rpc :Lookup, ::Talos::Internal::TMI::LookupRequest, ::Talos::Internal::TMI::LookupReply
  def self.lookup(mnemonics)
    lookup_request = ::Talos::Internal::TMI::LookupRequest.new(mnemonics: mnemonics)
    remote_stub.lookup(lookup_request)
  end

  def self.remote_stub
    @remote_stub ||= ::Talos::Internal::Service::TMI::Stub.new(hostport, creds)
  end
end

# grpcurl -cacert /usr/local/etc/tmi-root.cer  \
#         -key /usr/local/etc/tmi-pkey.pem \
#         -cert /usr/local/etc/tmi-certificate.pem \
#         -H 'x-request-source: timoport' \
#         -proto service-tmi-internal.proto \
#         -d '{"observation":{"domain":"google.com"}}' \
#         tmi-qa.sl.talos.cisco.com:50051 Talos.Internal.Service.TMI/Read