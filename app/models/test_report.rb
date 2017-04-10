class TestReport < ApplicationRecord
  belongs_to :task
  belongs_to :rule
end
