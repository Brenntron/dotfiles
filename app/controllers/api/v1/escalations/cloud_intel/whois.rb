module API
  module V1
    module Escalations
      module CloudIntel
        class Whois < Grape::API
          include API::V1::Defaults

          resource "escalations/cloud_intel/whois" do

            desc 'whois lookup'
            params do
              requires :name, type: String
            end
            get "lookup", root: "whois" do
              byebug
              Beaker::Whois.new.lookup(permitted_params['name'])
              raise 'unimplemented'
            end
          end
        end
      end
    end
  end
end
