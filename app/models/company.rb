class Company < ApplicationRecord
  has_many :customers
  validates :name, presence: true, uniqueness: true

  def self.thread_safe_find_or_create_by(attributes)
    with_advisory_lock("company_create", timeout_seconds: 20) do
      find_or_create_by(attributes)
    end
  end
end
