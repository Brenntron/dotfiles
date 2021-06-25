class WebcatCredit < ApplicationRecord
  belongs_to :user, optional: true

  PENDING = 'pending'.freeze
  UNCHANGED = 'unchanged'.freeze
  FIXED = 'fixed'.freeze
  INVALID = 'invalid'.freeze
  DUPLICATE = 'duplicate'.freeze
end
