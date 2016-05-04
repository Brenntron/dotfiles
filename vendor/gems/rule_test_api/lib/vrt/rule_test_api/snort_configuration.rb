# Class for managing snort configurations in RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class SnortConfiguration
  include Her::Model;

  has_many :engines

  # Internal record ID.
  # attr_reader :id

  # The snort configuration data.
  # attr_accessor :config_data

  # The name of the snort configuration. 
  # attr_accessor :name
end
