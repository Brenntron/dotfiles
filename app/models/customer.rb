class Customer < ApplicationRecord
  belongs_to :company
  has_many :complaints
  has_many :disputes

  validates :email, presence: true, uniqueness: true


  def self.process_and_get_customer(payload)
    customer_email = payload["email"]
    customer_company = payload["user_company"]
    customer_name = payload["name"]

    customer_exists = Customer.find_or_create_by(:email => customer_email)
    company_exists = Company.find_or_create_by(name: customer_company)

    customer_exists.company_id = company_exists.id
    customer_exists.name = customer_name
    customer_exists.save

    customer_exists

  end
end