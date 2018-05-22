module API
  module V1
    module Escalations
      module WebrepDisputes
        class Disputes < Grape::API
          include API::V1::Defaults

          resource "escalations/webrep_disputes/disputes" do
            
            desc 'get all disputes'
            params do
            end

            get "" do

            end

            desc 'update a dispute'
            params do
            end

            put ":id" do

            end

            desc 'delete a dispute'
            params do
            end

            delete "" do

            end

          end
        end
      end
    end
  end
end
