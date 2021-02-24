class UserPreference < ApplicationRecord
  belongs_to :user

  WEB_REP_COLUMNS = 'WebRepColumns'
end
