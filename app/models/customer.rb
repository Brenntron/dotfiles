class Customer < ApplicationRecord
  belongs_to :company, optional:true
  has_many :complaints
  has_many :disputes
  has_many :file_reputation_tickets

  validates :email, presence: true, uniqueness: true

  def self.thread_safe_find_or_create_by(attributes)
    with_advisory_lock("customer_create", timeout_seconds: 20) do
      find_by(email: attributes[:email]) || create(attributes)
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

  def self.find_or_create_customer(customer_email:, company_name:, name:)
    company_exists = Company.thread_safe_find_or_create_by(name: company_name)

    Customer.thread_safe_find_or_create_by(email: customer_email, company: company_exists, name: name)

  rescue
    sleep(15)
    company_exists = Company.thread_safe_find_or_create_by(name: company_name)

    Customer.thread_safe_find_or_create_by(email: customer_email, company: company_exists, name: name)
  end

  def self.process_and_get_customer(payload)

    if payload[:customer].present?
      if payload[:customer][:company_name] && payload[:customer][:name]
        customer_exists =
            find_or_create_customer(customer_email: payload[:customer][:customer_email],
                                    company_name: payload[:customer][:company_name],
                                    name: payload[:customer][:name])
      else
        customer_exists = Customer.thread_safe_find_or_create_by(email: "guest@cisco.com", name: "Guest", company:Company.find_by_name("Guest"))
      end

      return customer_exists
    end

    if payload["payload"] && payload["payload"]["email"] && payload["payload"]["user_company"] && payload["payload"]["name"]
      customer_exists =
          find_or_create_customer(customer_email: payload["payload"]["email"],
                                  company_name: payload["payload"]["user_company"],
                                  name: payload["payload"]["name"])
    else
      customer_exists = Customer.thread_safe_find_or_create_by(email: "guest@cisco.com", name: "Guest", company:Company.find_by_name("Guest"))
    end

    customer_exists
  end
end
