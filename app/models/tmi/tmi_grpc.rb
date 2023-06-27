require "service-tmi-internal_services_pb"

class Tmi::TmiGrpc < Tmi::TmiBase

  #only give one of the following: domain, url, ip, sha
  def self.read(domain: nil, url: nil, ip: nil, sha: nil)
    observable = get_observable(domain: domain, url: url, ip: ip, sha: sha)

    read_request = ::Talos::Internal::TMI::ReadRequest.new(observation: observable)
    remote_stub.read(read_request)
  end

  # rpc :UpdateByContext, ::Talos::Internal::TMI::UpdateRequest, ::Talos::Internal::TMI::UpdateReply
  def self.update_by_context(items: [])

    update_items = []
    items.each do |item|
      observable = get_observable(domain: item[:domain], url: item[:url], ip: item[:ip], sha: item[:sha])
      action = get_action(item[:action])

      context_tags = []
      item[:tags].each do |tag|
        context_tags << ::Talos::Internal::TMI::ContextTag.new(
            tag_type_id: tag[:tag_type_id],
            taxonomy_id: tag[:taxonomy_id],
            taxonomy_entry_id: tag[:taxonomy_entry_id],
            tag_val_uint32: tag[:tag_val_uint32],
            tag_val_uint64: tag[:tag_val_uint64],
            tag_val_string: tag[:tag_val_string],
            tag_val_bytes: tag[:tag_val_bytes],
            tag_key_string: tag[:tag_key_string],
            external_id: tag[:external_id]
        )
      end

      update_items << ::Talos::Internal::TMI::UpdateItem.new(observation: observable,
                                                             action: action,
                                                             tags: context_tags,
                                                             suppress_target: get_data_source)
    end

    update_request = ::Talos::Internal::TMI::UpdateRequest.new(items: update_items)
    remote_stub.update_by_context(update_request)
  end

  #only give one of the following: domain, url, ip, sha.
  #tag_memonics should be an array of strings
  def self.update_by_mnemonic(domain: nil,
                              url: nil,
                              ip: nil,
                              sha: nil,
                              action: nil,
                              tag_mnemonics: [])

    observable = get_observable(domain: domain, url: url, ip: ip, sha: sha)

    mnemonic_update_item = ::Talos::Internal::TMI::MnemonicUpdateItem.new(observation: observable,
                                                                          action: get_action(action),
                                                                          tag_mnemonics: tag_mnemonics,
                                                                          suppress_target: get_data_source)

    mnemonic_update_request = ::Talos::Internal::TMI::MnemonicUpdateRequest.new(mnemonic_update_item: mnemonic_update_item)
    remote_stub.update_by_mnemonic(mnemonic_update_request)
  end

  # rpc :Lookup, ::Talos::Internal::TMI::LookupRequest, ::Talos::Internal::TMI::LookupReply
  def self.lookup(mnemonics)
    lookup_request = ::Talos::Internal::TMI::LookupRequest.new(mnemonics: mnemonics)
    remote_stub.lookup(lookup_request)
  end

  def self.get_observable(domain: nil, url: nil, ip: nil, sha: nil)
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

    observable
  end

  def self.get_action(action)
    case action
    when "add"
      ::Talos::Internal::TMI::Action::UPDATE_ADD
    when "delete"
      ::Talos::Internal::TMI::Action::UPDATE_DELETE
    when "replace"
      ::Talos::Internal::TMI::Action::UPDATE_REPLACE
    when "suppress report"
      ::Talos::Internal::TMI::Action::UPDATE_SUPPRESS_REPORT
    when "unsuppress report"
      ::Talos::Internal::TMI::Action::UPDATE_UNSUPPRESS_REPORT
    when "suppress tag group"
      ::Talos::Internal::TMI::Action::UPDATE_SUPPRESS_TAG_GRP
    when "unsuppress tag group"
      ::Talos::Internal::TMI::Action::UPDATE_UNSUPPRESS_TAG_GRP
    when "suppress source"
      ::Talos::Internal::TMI::Action::UPDATE_SUPPRESS_SOURCE
    when "unsuppress source"
      ::Talos::Internal::TMI::Action::UPDATE_UNSUPPRESS_SOURCE
    when "suppress observation"
      ::Talos::Internal::TMI::Action::UPDATE_SUPPRESS_OBSERVATION
    when "unsuppress observation"
      ::Talos::Internal::TMI::Action::UPDATE_UNSUPPRESS_OBSERVATION
    else
      raise Tmi::TmiError, "Invalid Action"
    end
  end

  def self.get_data_source
    source = current_user.cvs_username || "vrtincom"
    processor = Rails.configuration.app_info.product_id
    ::Talos::Internal::TMI::DataSource.new(source: source, processor: processor)
  end

  def self.remote_stub
    @remote_stub ||= ::Talos::Internal::Service::TMI::Stub.new(hostport, creds)
  end
end
