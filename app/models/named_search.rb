class NamedSearch < ApplicationRecord

  belongs_to :user

  has_many :named_search_criteria, dependent: :destroy

  validates :user_id, :name, presence: true

  scope :where_project_type, ->(project_type) { where(project_type: project_type) }

end
