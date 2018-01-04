class ReferenceType < ApplicationRecord
  has_many :references

  def self.valid_reference_type_ids
    self.where(:name => ['cve', 'url', 'bugtraq', 'osvdb']).pluck(:id)
  end

  def self.valid_reference_types
    self.where(:name => ['cve', 'url', 'bugtraq', 'osvdb'])
  end

  def self.cve
    ReferenceType.find_by_name('cve')
  end

  def self.bugtraq
    ReferenceType.find_by_name('bugtraq')
  end

  def self.telus
    ReferenceType.find_by_name('telus')
  end

  def self.apsb
    ReferenceType.find_by_name('apsb')
  end

  def self.url
    ReferenceType.find_by_name('url')
  end

  def self.msb
    ReferenceType.find_by_name('msb')
  end

  def self.osvdb
    ReferenceType.find_by_name('osvdb')
  end
end
