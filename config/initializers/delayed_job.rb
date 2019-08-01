module Delayed
  module Backend
    module Base
      def last_error=(err_message)
        write_attribute :last_error, err_message.truncate(1000000, omission: "...error message truncated")
      end
    end
  end
end