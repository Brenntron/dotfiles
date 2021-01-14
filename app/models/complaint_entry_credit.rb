class ComplaintEntryCredit < ApplicationRecord
  belongs_to :user
  belongs_to :complaint_entry

  PENDING = 'pending'.freeze
  UNCHANGED = 'unchanged'.freeze
  FIXED = 'fixed'.freeze
  INVALID = 'invalid'.freeze
  DUPLICATE = 'duplicate'.freeze
end
