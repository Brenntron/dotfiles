module API
  module V1
    module Escalations
      module FileRep
        class AmpNamingConvention < Grape::API
          include API::V1::Defaults
          # include API::BugzillaRestSession

          resource "escalations/file_rep/amp_naming_convention" do

            desc 'Create an AMP Naming Convention record through the form'
            params do
              requires :pattern, type: String
              requires :example, type: String
              requires :engine, type: String
              requires :engine_description, type: String
              requires :notes, type: String
              requires :public_notes, type: String
              requires :contact, type: String
              optional :table_sequence, type: Integer
            end
            post "" do
              std_api_v2 do
                conv = ::AmpNamingConvention.create!(params)

                render json: {status: 'Success', id: conv.id}
              end
            end

            desc 'Edit an AMP Naming Convention record through the form'
            params do
              requires :pattern, type: String
              requires :example, type: String
              requires :engine, type: String
              requires :engine_description, type: String
              requires :notes, type: String
              requires :public_notes, type: String
              requires :contact, type: String
              optional :table_sequence, type: Integer
            end
            put ":id" do
              std_api_v2 do
                conv = ::AmpNamingConvention.find(params['id'])
                conv.update!(params.reject {|key, value| 'id' == key.to_s })

                render json: {status: 'Success', id: conv.id}
              end
            end
          end
        end
      end
    end
  end
end
