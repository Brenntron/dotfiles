class UserApiKey < ApplicationRecord
  belongs_to :user

  def self.generate_key
    SecureRandom.base64(60)
  end

  after_initialize do |key|
    key.api_key ||= UserApiKey.generate_key
  end
end
