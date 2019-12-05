module API
  module V1
    module Escalations
      module Webcat
        class Companies < Grape::API
          include API::V1::Defaults
            resource "escalations/webcat/companies" do

              desc "get all company names"
              params do
              end
              get "" do
                companies = Company.all.map {|company| {company_id: company.id, company_name: company.name}}

                companies.to_json
              end
            end
        end
      end
    end
  end
end
