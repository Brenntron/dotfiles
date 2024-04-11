module API
  module V1
    module Escalations
      module Webcat
        class Platforms < Grape::API
          include API::V1::Defaults

          resource "escalations/webcat/platforms_names" do
            desc "get all platforms' names"
            params do
            end

            get "" do
              platfoms = Platform.all.map {|m| {id: m.id, public_name: m.public_name}}
              {:data => platfoms}
            end
          end
        end
      end
    end
  end
end
