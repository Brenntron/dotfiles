# Class for managing pcap tests in RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class PcapTest
  include Her::Model;

  belongs_to :pcap
  belongs_to :job  
  
  has_many :alerts

  # Job ID - The job definition that this PCAP should be tested against.
  attr_accessor :job_id

  # Extra information about the test not found in the other fields.
  attr_accessor :information

  # Defines if the test completed successfully?
  attr_accessor :failed

  # Timestamp when the test is created.
  attr_accessor :created_at

  # Timestamp when the test was completd.
  attr_accessor :updated_at

  # Internal record ID.
  attr_reader :id

  # Defines if the test is still running.
  attr_accessor :completed

end
