class WebcatCredit < ApplicationRecord
  belongs_to :user, optional: true

  INTERNAL = 'internal'.freeze
  PENDING = 'pending'.freeze
  UNCHANGED = 'unchanged'.freeze
  FIXED = 'fixed'.freeze
  INVALID = 'invalid'.freeze
  DUPLICATE = 'duplicate'.freeze
end
