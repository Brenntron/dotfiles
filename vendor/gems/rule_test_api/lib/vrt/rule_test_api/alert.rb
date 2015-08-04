# Class for accessing alerts from RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class Alert
  include Her::Model

  belongs_to :pcap_test
  
  # Internal record ID
  attr_reader :id

  # PcapTest ID - Defines the pcap and engine to test.
  attr_accessor :pcap_test_id 

  # Snort rule generator ID
  attr_accessor :gid

  # Snort rule signature ID
  attr_accessor :sid

  # Snort rule signature revision
  attr_accessor :rev

  # Snort rule signature messsage
  attr_accessor :msg

  # Related information not included in the other fields
  attr_accessor :information

end
