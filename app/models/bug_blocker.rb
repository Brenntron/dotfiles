class BugBlocker < ApplicationRecord
  belongs_to :snort_blocker_bug, class_name: "Bug"
  belongs_to :snort_blocked_bug, class_name: "Bug"
end
