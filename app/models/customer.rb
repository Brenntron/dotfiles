class Customer < ApplicationRecord
  belongs_to :company
  has_many :complaints
  has_many :disputes
  has_many :amp_false_positives

  validates :email, presence: true, uniqueness: true

  def self.thread_safe_find_or_create_by(attributes)
    with_advisory_lock("customer_create", timeout_seconds: 20) do
      find_or_create_by(attributes)
    end
  end

  def self.customer_from_ruleui(data)

    wbnp_company = Company.find_or_create_by(:name => "WBNP")

    ti_company_format = data["customer_name"].downcase.gsub(/[[:space:]]/, '')
    email = "wbnp-#{ti_company_format}@talosintelligence.com"

    customer = Customer.where(:email => email).first
    if customer.blank?
      customer = Customer.new
      customer.company_id = wbnp_company.id
      customer.name = data["customer_name"]
      customer.email = email
      customer.save
    end
    customer.reload

    customer

  end

  def self.process_and_get_customer(payload)
    if payload["payload"] && payload["payload"]["email"] && payload["payload"]["user_company"] && payload["payload"]["name"]
      customer_email = payload["payload"]["email"]

      customer_company = payload["payload"]["user_company"]
      customer_name = payload["payload"]["name"]

      customer_exists = Customer.thread_safe_find_or_create_by(email: customer_email)
      if customer_exists.new_record?
        company_exists = Company.thread_safe_find_or_create_by(name: customer_company)

        customer_exists.company_id = company_exists.id
        customer_exists.name = customer_name
        customer_exists.save!
      end
    else
      customer_exists = nil
    end

    customer_exists
  end
end
