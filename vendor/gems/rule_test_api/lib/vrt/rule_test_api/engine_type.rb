# Class for managing engine types for RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class EngineType
  include Her::Model;

  has_many :engines

  # Internal record ID
  attr_reader :id

  # The name of the engine type (Peristent, Single, etc)
  attr_accessor :name

  # Defines whether each pcap should be sent seperately or all in the same job.
  attr_accessor :submit_as_job

end
