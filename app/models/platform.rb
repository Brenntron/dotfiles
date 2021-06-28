class Platform < ApplicationRecord

  def self.process_bridge_payload(message_payload)

    payload = message_payload[:attributes]
    action = message_payload[:action]

    case action

    when "update"
      process_update(payload)
    when "create"
      process_create(payload)
    when "destroy"
      process_destroy(payload)
    end

    conn = ::Bridge::PlatformEvent.new(addressee: "talos-intelligence", source_authority: "talos-intelligence", source_key: message_payload["source_key"])

    conn.post(action: action)
  end

  def self.process_destroy(payload)
    platform = Platform.find(payload["id"])
    platform.destroy
  end

  def self.process_create(payload)
    platform = Platform.new(payload)
    platform.save
  end

  def self.process_update(payload)
    platform = Platform.where(:id => payload["id"]).first
    if platform.blank?
      platform = Platform.new(payload)
      platform.save
    else
      platform.update_attributes(payload)
    end

  end

  def self.find_by_all_names(name)
    platform = Platform.where("public_name like '%name%' or internal_name like '%name%'").first
    platform
  end
end
