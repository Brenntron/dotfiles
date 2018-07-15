class Wbrs::ManualWlbl < Wbrs::Base
  FIELD_NAMES = %w{id ctime list_type mtime threat_cats url username state}
  FIELD_SYMS = FIELD_NAMES.map{|name| name.to_sym}


  attr_accessor *FIELD_SYMS

  def self.new_from_attributes(attributes)
    new(attributes.slice(*FIELD_NAMES))
  end

  # Get all the manual WL/BL entries.
  # @return [Array<Wbrs::ThreatCategory>] Array of the results.
  def self.types
    unless @types
      response = call_json_request(:get, '/v1/rep/wlbl/types/get', body: {})

      response_body = JSON.parse(response.body)
      @types = response_body['data']
    end
    @types
  end

  # @param [Integer] id the WL/BL
  # @return [Wbrs::Prefix] the WL/BL
  def self.find(id)
    response = call_json_request(:get, "/v1/rep/wlbl/get/#{id}", body: {})

    response_body = JSON.parse(response.body)
    new_from_attributes(response_body)
  end

  def self.load_from_prefetch(data)
    data = JSON.parse(data)
    data['data'].map {|datum| new_from_attributes(datum)}
  end

  # Get all the manual WL/BL entries.
  # @param [String] url URL pattern the WL/BL entry is added for (optional)
  # @param [String] usr Pattern of username who added or modified WL/BL entry (optional)
  # @param [Array<String>] list_types The WL/BL entry’s type (optional)
  # @return [Array<Wbrs::ThreatCategory>] Array of the results.
  def self.where(conditions = {}, raw = false)
    params = stringkey_params(conditions)
    response = post_request(path: '/v1/rep/wlbl/get', body: params)
    return response.body if raw == true
    response_body = JSON.parse(response.body)
    response_body['data'].map {|datum| new_from_attributes(datum)}
  end

  # Add a WL/BL on the backend
  # @param [Array<DisputeEntry>] entries the database records for the entries to add the WL/BL to.
  # @param [String] trgt_list: Target manual list type
  # @param [String] usr: User creating the WL/BL entries
  # @param [Array<String>] thrt_cats: List of up to five unique threat categories IDs
  # @param [String] note: User’s note
  # @return [String] JSON for array of warnings
  def self.add_from_params(entries, wlbl_params)
    wlbl_params['url'] = entries.map {|entry| entry.hostlookup}
    response = post_request(path: '/v1/rep/wlbl/add', body: wlbl_params)
    wlbl_params.delete('url')

    wlbl_ids = JSON.parse(response.body)["Added WL/BL entries IDs"]
    wlbl_ids.each_with_index do |wlbl_id, index|
      entries[index].update(webrep_wlbl_key: wlbl_id)
    end

    response.body
  end

  def self.edit_from_params(entries, wlbl_params)
    entries.each do |entry|
      wlbl_params['wlbl_id'] = entry.webrep_wlbl_key
      post_request(path: '/v1/rep/wlbl/edit', body: wlbl_params)
      wlbl_params.delete('wlbl_id')
    end

    ''
  end

  def self.drop_from_params(entries, wlbl_params)
    wlbl_params['ids'] = entries.map {|entry| entry.webrep_wlbl_key}
    response = post_request(path: '/v1/rep/wlbl/drop', body: wlbl_params)
    wlbl_params.delete('ids')

    entries.each { |entry| entry.update(webrep_wlbl_key: nil) }

    response.body
  end

  # Add a WL/BL on the backend
  # @param [Array<Integer>] dispute_entry_ids pkey for dispute_entries database table.
  # @param [String] trgt_list: Target manual list type
  # @param [String] username: User creating the WL/BL entries
  # @param [Array<String>] thrt_cats: List of up to five unique threat categories IDs
  # @param [String] note: User’s note
  # @return [Array<String>] warnings
  def self.adjust_from_params(params = {}, username:)
    wlbl_params = stringkey_params(params)
    wlbl_params['usr'] = username

    target_list = wlbl_params['trgt_list']

    entries = wlbl_params.delete('dispute_entry_ids').map {|id| DisputeEntry.find(id)}
    existing_entries, new_entries = entries.partition{ |entry| entry.webrep_wlbl_key.present? }

    # when no current wlbl, then add
    if new_entries.any? && target_list.present?
      add_from_params(new_entries, wlbl_params)
    end

    if existing_entries.any?
      if target_list.present? # when current wlbl and a target list, then edit
        edit_from_params(existing_entries, wlbl_params)
      else # when current wlbl and no target list, then drop
        drop_from_params(existing_entries, wlbl_params)
      end
    end
  end
end
