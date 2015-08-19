# Class for managing jobs in RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class Job
  include Her::Model;

  has_many :pcap_tests
  belongs_to :engine

  # Engine ID - The defined engine that should run this job.
  attr_accessor :engine_id 

  # Extra information about the job not found in the other fields.
  attr_accessor :information

  # Defines if the job completed successfully?
  attr_accessor :failed

  # Timestamp when the job is created.
  attr_accessor :created_at

  # Timestamp when the job was completd.
  attr_accessor :updated_at

  # Internal record ID.
  attr_reader :id

  # Defines if the job is still running.
  attr_accessor :completed

  # Performance statistics from the job run.  This is only available for certain job types.
  attr_accessor :perf_stats

   
end
