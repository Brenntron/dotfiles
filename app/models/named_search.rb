class NamedSearch < ApplicationRecord

  belongs_to :user

  has_many :named_search_criteria

  validates :user_id, :name, presence: true

end
