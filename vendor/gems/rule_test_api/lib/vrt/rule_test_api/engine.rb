# Class for managing engine definitions for RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class Engine
  include Her::Model;

  has_many :jobs
  belongs_to :rule_configuration
  belongs_to :snort_configuration
  belongs_to :engine_type

  # Internal record ID
  attr_reader :id

  # RuleConfiguration ID - The defined rule configuration to use with this engine.
  attr_accessor :rule_configuration_id

  # SnortConfiguration ID - The defined snort configuration to use with this engine.
  attr_accessor :snort_configuration_id

  # EngineType ID - (Persistent, Single, etc) Determines how this engine will be started.
  attr_accessor :engine_type_id

  # Defines how many of these instances will started by each running engine_manager.
  attr_accessor :instances


end
