# Base class for stubs for Bugzilla REST API, typically used from the derived classes.
#
# Stores fields of object in an attributes hash.
# Uses method_missing to alias the name of the attribute as getter and setter methods.
class BugzillaRest::Base
  include ActiveModel::Model

  attr_reader :fields, :api_key, :token, :attributes

end
