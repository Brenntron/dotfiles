class Relationship < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :team_member,
             class_name: 'User', optional: true
end
