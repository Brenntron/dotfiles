module Delayed
  module Backend
    module Base
      # QA: I recommend reducing the truncate limit to something small, i.e. 3 characters, to confirm it works
      def last_error=(err_message)
        write_attribute :last_error, err_message.truncate(1000000, omission: "...error message truncated")
      end
    end
    module ActiveRecord
      class Job
        class << self
          alias_method :reserve_original, :reserve
          def reserve(worker, max_run_time = Worker.max_run_time)
            previous_level = ::ActiveRecord::Base.logger.level
            ::ActiveRecord::Base.logger.level = Logger::WARN if previous_level < Logger::WARN
            value = reserve_original(worker, max_run_time)
            ::ActiveRecord::Base.logger.level = previous_level
            value
          end
        end
      end
    end
  end
end