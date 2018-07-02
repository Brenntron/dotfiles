class EmailTemplate < ApplicationRecord
  validates_presence_of :template_name, :body
end
