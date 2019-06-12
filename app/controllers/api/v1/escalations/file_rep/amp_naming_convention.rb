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
                ti_pattern = TiApi::AmpNamingPattern.new(params['patterns'])
                ti_pattern.update_ti!
                ::AmpNamingConvention.save_batch(ti_pattern.records)

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
                ti_pattern = TiApi::AmpNamingPattern.new(params['patterns'])
                ti_pattern.update_ti!
                ::AmpNamingConvention.save_batch(ti_pattern.records)

                render json: {status: 'Success'}
              end
            end

            desc 'Delete an AMP Naming Convention record through the form'
            params do
              requires :ids, type: Array[Integer]
            end
            delete "" do
              std_api_v2 do
                patterns = ::AmpNamingConvention.where(id: params['ids'])
                positions = patterns.pluck(:table_sequence)
                TiApi::AmpNamingPattern.delete_on_ti!(positions)
                patterns.destroy_all

                render json: {status: 'Success'}
              end
            end
          end
        end
      end
    end
  end
end
