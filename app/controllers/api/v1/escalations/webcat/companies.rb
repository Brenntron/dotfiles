module API
  module V1
    module Escalations
      module Webcat
        class Companies < Grape::API
          include API::V1::Defaults
            resource "escalations/webcat/companies" do

              desc "return company names as objects (for Selectize)"
              params do
              end
              get "" do
                companies = Company.all.map {|company| {company_name: company.name}}

                companies.sort_by {|hash| hash[:company_name]}.to_json
              end
            end
        end
      end
    end
  end
end
