require 'base64'

# Class for managing pcaps in RuleTestAPI. See https://github.com/remiprev/her for working with these classes.
class Pcap
  include Her::Model;

  has_many :pcap_tests

  # Internal record ID.
  # attr_reader :id

  # sha256 of the PCAP file data.
  # attr_accessor :file_hash

  # Search for an existing PCAP in the API or create it if it's not found.
  #
  # ==== Attributes
  #
  # +pcap_file+ - The local path to the PCAP file.
  #
  # ==== Examples
  #
  # pcap = Pcap.create("/tmp/some/file.pcap")
  def self.find_or_create(pcap_file)
    Pcap.create(pcap: Base64.encode64(File.read(pcap_file)))
  end
end
