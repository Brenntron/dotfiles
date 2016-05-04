# Class for managing snort rule configurations in RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class RuleConfiguration
  include Her::Model;

  has_many :engines

  # Internal record ID.
  # attr_reader :id

  # The rule configuration data.
  # attr_accessor :config_data

  # The name of the rule configuration. 
  # attr_accessor :name
  
end
