module API
  class Base < Grape::API
    mount API::V2::Base
    mount API::V1::Base
  end
end
