# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: guid.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("guid.proto", :syntax => :proto3) do
    add_message "Talos.GUID.Request" do
      optional :type_of_guid, :enum, 1, "Talos.GUID.Request.GUIDType"
    end
    add_enum "Talos.GUID.Request.GUIDType" do
      value :UNSPECIFIED, 0
      value :CONNECTION_ID, 1
      value :MESSAGE_ID, 2
      value :TRANSACTION_ID, 3
    end
    add_message "Talos.GUID.Reply" do
      optional :guid_bin, :bytes, 1
    end
  end
end

module Talos
  module GUID
    Request = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.GUID.Request").msgclass
    Request::GUIDType = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.GUID.Request.GUIDType").enummodule
    Reply = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.GUID.Reply").msgclass
  end
end
