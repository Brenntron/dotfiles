class Relationship < ActiveRecord::Base
  belongs_to :user
  belongs_to :team_member,
             class_name: 'User'
end
