module Delayed
  module Backend
    module Base
      # QA: I recommend reducing the truncate limit to something small, i.e. 3 characters, to confirm it works
      def last_error=(err_message)
        write_attribute :last_error, err_message.truncate(1000000, omission: "...error message truncated")
      end
    end
  end
end