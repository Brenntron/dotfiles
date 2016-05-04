# Class for managing jobs in RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class Job
  include Her::Model;

  has_many :pcap_tests
  belongs_to :engine
end
