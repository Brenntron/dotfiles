module API
  module V1
    module Escalations
      module FileRep
        class AmpNamingConvention < Grape::API
          include API::V1::Defaults

          resource "escalations/file_rep/amp_naming_convention" do

            desc 'Create an AMP Naming Convention record through the form'
            params do
              requires :patterns, type: Array do
                requires :pattern, type: String
                requires :example, type: String
                requires :engine, type: String
                optional :engine_description, type: String
                optional :notes, type: String
                optional :public_notes, type: String
                optional :contact, type: String
                optional :table_sequence, type: Integer
              end
            end
            post "" do
              std_api_v2 do
                ::AmpNamingConvention.transaction do
                  timestamp = Time.now
                  Rails.logger.debug("\n\n*** POST #{params['patterns']}\n\n")
                  ::AmpNamingConvention.create_from_params(params['patterns'])
                  ::AmpNamingConvention.send_all_to_ti(timestamp: timestamp)
                end

                render json: {status: 'Success'}
              end
            end

            desc 'Edit an AMP Naming Convention record through the form'
            params do
              requires :patterns, type: Array do
                requires :pattern, type: String
                requires :example, type: String
                requires :engine, type: String
                optional :engine_description, type: String
                optional :notes, type: String
                optional :public_notes, type: String
                optional :contact, type: String
                optional :table_sequence, type: Integer
              end
            end
            patch "" do
              std_api_v2 do
                ::AmpNamingConvention.transaction do
                  timestamp = Time.now
                  Rails.logger.debug("\n\n*** PATCH #{params['patterns']}\n\n")
                  ::AmpNamingConvention.save_from_params(params['patterns'])
                  ::AmpNamingConvention.send_all_to_ti(timestamp: timestamp)
                end

                render json: {status: 'Success'}
              end
            end

            desc 'Delete an AMP Naming Convention record through the form'
            params do
              requires :ids, type: Array[Integer]
            end
            delete "" do
              std_api_v2 do
                ::AmpNamingConvention.transaction do
                  timestamp = Time.now
                  patterns = ::AmpNamingConvention.where(id: params['ids'])
                  Rails.logger.debug("*** DELETE #{params['ids']}")
                  patterns.destroy_all
                  ::AmpNamingConvention.send_all_to_ti(timestamp: timestamp)
                end

                render json: {status: 'Success'}
              end
            end
          end
        end
      end
    end
  end
end
