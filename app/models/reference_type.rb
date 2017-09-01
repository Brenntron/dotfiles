class ReferenceType < ApplicationRecord
  has_many :references

  def self.valid_reference_type_ids
    self.where(:name => ['cve', 'url', 'bugtraq', 'osvdb']).pluck(:id)
  end

  def self.valid_reference_types
    self.where(:name => ['cve', 'url', 'bugtraq', 'osvdb'])
  end
end
