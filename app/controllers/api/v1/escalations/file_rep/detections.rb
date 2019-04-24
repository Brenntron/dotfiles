module API
  module V1
    module Escalations
      module FileRep
        class Detections < Grape::API
          include API::V1::Defaults
          include API::BugzillaRestSession
          resource "escalations/file_rep/detections" do

            desc 'Create detection'
            params do
              optional :ids, type: Array[Integer]
              optional :sha256_hashes, type: Array[String], desc: "SHA256 hashes"
              optional :disposition, type: String
              optional :detection, type: Hash
            end
            post "" do
              std_api_v2 do
                byebug
              end
            end
          end
        end
      end
    end
  end
end
