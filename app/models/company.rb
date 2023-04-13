class Company < ApplicationRecord
  has_many :customers
  validates :name, presence: true, uniqueness: { case_sensitive: true }

  scope :is_guest, -> { where(name: 'Guest') }

  def self.guest
    @guest = is_guest.first || (raise("Guest record missing"))
  end

  def self.thread_safe_find_or_create_by(attributes)
    begin
      with_advisory_lock("company_create", timeout_seconds: 20) do
        find_or_create_by(attributes)
      end
    rescue Exception => e
      Rails.logger.error e
      raise "Failed to create new Company with the following attributes: '#{attributes}'"
    end
  end
end
