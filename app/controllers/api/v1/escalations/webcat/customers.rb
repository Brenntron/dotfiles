module API
  module V1
    module Escalations
      module Webcat
        class Customers < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/customers" do

            desc "get all customers"
            params do
            end

            get "" do

              customers = Customer.all.includes(:company).map do |customer|
                "#{customer.company&.name}:#{customer.name}:#{customer.email}"
              end
              {:data => customers}
            end
          end

          resource "escalations/webcat/customers_names" do

            desc "get all customers' names"
            params do
            end

            get "" do

              customers = Customer.all.pluck(:name)
              {:data => customers}

            end
          end

          resource "escalations/webcat/customers_names_selectize" do
            desc "get all customers' names as objects (for Selectize)"
            get '' do
              Customer.order(:name).pluck(:name).map { |name| { name: name } }.to_json
            end
          end

          resource "escalations/webcat/customers_company_name" do

            desc "get all customers' names"
            params do
            end

            get "" do

              customers = Customer.all.includes(:company).map{ |customer| "#{customer.company&.name}"}
              {:data => customers}

            end
          end

          resource "escalations/webcat/customers_email" do

            desc "get all customers' names"
            params do
            end

            get "" do

              customers = Customer.all.pluck(:email)
              {:data => customers}

            end
          end
        end
      end
    end
  end
end
