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

              customers = Customer.all.includes(:company).map{ |customer| "#{customer.company.name}:#{customer.name}:#{customer.email}"}
              {:data => customers}

            end
          end

          resource "escalations/webcat/customers_names" do

            desc "get all customers' names"
            params do
            end

            get "" do

              customers = Customer.all.includes(:company).map{ |customer| "#{customer.name}"}
              {:data => customers}

            end
          end

          resource "escalations/webcat/customers_company_name" do

            desc "get all customers' names"
            params do
            end

            get "" do

              customers = Customer.all.includes(:company).map{ |customer| "#{customer.company.name}"}
              {:data => customers}

            end
          end

          resource "escalations/webcat/customers_email" do

            desc "get all customers' names"
            params do
            end

            get "" do

              customers = Customer.all.includes(:company).map{ |customer| "#{customer.email}"}
              {:data => customers}

            end
          end
        end
      end
    end
  end
end