module API
  module V1
    module Escalations
      module Webcat
        class Customers < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/customers" do

            desc 'get all customers'
            params do
            end

            get "" do

              customers = Customer.all.includes(:company).map{ |customer| "#{customer.name}(#{customer.company.name})"}
              {:data => customers}

            end
          end
        end
      end
    end
  end
end