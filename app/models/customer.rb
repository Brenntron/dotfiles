class Customer < ApplicationRecord
  belongs_to :company
  has_many :complaints
  has_many :disputes

  validates :email, presence: true, uniqueness: true


  def self.process_and_get_customer(payload)
    customer_email = payload["email"]
    customer_company = payload["user_company"]
    customer_name = payload["name"]

    customer_exists = Customer.where(:email => customer_email).first
    company_exists = Company.where(:name => customer_company).first

    if company_exists.blank?
      company_exists = Company.create(:name => customer_company)
    end

    if customer_exists.present?
      if customer_exists.name != customer_name
        customer_exists.name = customer_name
        customer_exists.save
      end

      if customer_exist.company.name != customer_company
        if company_exists.present?
          new_company = company_exists
        else
          new_company = Company.create(:name => customer_company)
        end
        customer_exists.company_id = new_company.id
        customer_exists.save
      end
    else
      customer_exists = Customer.create({:name => customer_name, :email => customer_email, :company_id => company_exists.id})
    end

    customer_exists

  end
end