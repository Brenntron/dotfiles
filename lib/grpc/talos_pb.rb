# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: talos.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("talos.proto", :syntax => :proto3) do
    add_message "Talos.IPConnection" do
      optional :direction, :enum, 1, "Talos.IPConnection.Direction"
      optional :proto, :enum, 2, "Talos.IPConnection.Protocol"
      optional :guid, :bytes, 3
    end
    add_enum "Talos.IPConnection.Direction" do
      value :IP_DIR_IN, 0
      value :IP_DIR_OUT, 1
    end
    add_enum "Talos.IPConnection.Protocol" do
      value :IP_PROTO_TCP, 0
      value :IP_PROTO_UDP, 1
    end
    add_message "Talos.IPEndpoint" do
      optional :port, :int32, 3
      repeated :hostname, :string, 4
      optional :role, :enum, 5, "Talos.IPEndpoint.ConnectionRole"
      optional :connection, :message, 6, "Talos.IPConnection"
      oneof :address do
        optional :ipv4_addr, :fixed32, 1
        optional :ipv6_addr, :bytes, 2
      end
    end
    add_enum "Talos.IPEndpoint.ConnectionRole" do
      value :CONNECTION_ROLE_NONE, 0
      value :CONNECTION_ROLE_PEER, 1
      value :CONNECTION_ROLE_LOCAL, 2
    end
    add_message "Talos.SMTPEnvelope" do
      optional :mail_from, :string, 3
      repeated :rcpt_to, :string, 4
      optional :auth, :bool, 5
      optional :spf_results, :message, 6, "Talos.SPFResults"
      oneof :greeting do
        optional :helo, :string, 1
        optional :ehlo, :string, 2
      end
    end
    add_message "Talos.MailData" do
      repeated :from_hdr, :message, 1, "Talos.EmailMailbox"
      repeated :to_hdr, :message, 2, "Talos.EmailMailbox"
      repeated :reply_to_hdr, :message, 3, "Talos.EmailMailbox"
      optional :list, :message, 4, "Talos.EmailList"
      optional :dkim_disabled, :bool, 5
      repeated :dkim_disp, :message, 6, "Talos.DKIMDisposition"
      optional :dmarc_disabled, :bool, 7
      optional :dmarc_disp, :message, 8, "Talos.DMARCDisposition"
      repeated :misc_hdrs, :message, 9, "Talos.EmailHeader"
    end
    add_message "Talos.EmailMailbox" do
      optional :addr, :string, 1
      optional :display, :string, 2
    end
    add_message "Talos.EmailList" do
      repeated :help, :string, 1
      repeated :unsubscribe, :string, 2
      repeated :subscribe, :string, 3
      repeated :post, :string, 4
      repeated :owner, :string, 5
      repeated :archive, :string, 6
      optional :unsub_post, :enum, 7, "Talos.EmailList.EmailListUnsubPost"
    end
    add_enum "Talos.EmailList.EmailListUnsubPost" do
      value :EMAIL_LISTUNSUBPOST_NONE, 0
      value :EMAIL_LISTUNSUBPOST_VALID, 1
      value :EMAIL_LISTUNSUBPOST_INVALID, 2
    end
    add_message "Talos.EmailHeader" do
      optional :name, :string, 1
      optional :value, :string, 2
    end
    add_message "Talos.SPFResults" do
      optional :helo, :enum, 2, "Talos.SPFResults.ResultType"
      optional :mail_from, :enum, 3, "Talos.SPFResults.ResultType"
      optional :dmarc_align, :bool, 4
    end
    add_enum "Talos.SPFResults.ResultType" do
      value :SPF_RESULT_NONE, 0
      value :SPF_RESULT_NEUTRAL, 1
      value :SPF_RESULT_PASS, 2
      value :SPF_RESULT_FAIL, 3
      value :SPF_RESULT_SOFTFAIL, 4
      value :SPF_RESULT_TEMPERROR, 5
      value :SPF_RESULT_PERMERROR, 6
      value :SPF_RESULT_NOT_IMPLEMENTED, 7
    end
    add_message "Talos.DKIMDisposition" do
      optional :domain, :string, 1
      optional :selector, :string, 2
      optional :head_canon, :enum, 3, "Talos.DKIMDisposition.DKIMCanon"
      optional :body_canon, :enum, 4, "Talos.DKIMDisposition.DKIMCanon"
      optional :dmarc_align, :bool, 5
      optional :uses_from_hdr, :bool, 6
      optional :dkim_sig_is_valid, :bool, 7
    end
    add_enum "Talos.DKIMDisposition.DKIMCanon" do
      value :DKIM_CANON_RELAXED, 0
      value :DKIM_CANON_STRICT, 1
    end
    add_message "Talos.DMARCDisposition" do
      optional :record, :string, 1
      optional :strict, :bool, 2
      optional :aligned, :bool, 3
    end
    add_message "Talos.AppInfo" do
      optional :device_id, :string, 1
      optional :product_family, :string, 2
      optional :product_id, :string, 3
      optional :product_version, :string, 4
      optional :tenant_id, :bytes, 5
      optional :perf_testing, :bool, 6
      repeated :service_chain, :string, 7
    end
    add_message "Talos.GeoCoords" do
      optional :longitude, :float, 1
      optional :latitude, :float, 2
      optional :precision, :uint32, 3
      optional :last_update_timestamp, :uint64, 4
      optional :longitude_x10000, :sint32, 5
      optional :latitude_x10000, :sint32, 6
    end
    add_message "Talos.GeoLocation" do
      optional :locality, :string, 1
      optional :state_or_province, :string, 2
      optional :postal_code, :string, 3
      optional :country, :string, 4
    end
    add_message "Talos.LocalizedString" do
      optional :language, :string, 1
      optional :text, :string, 2
    end
    add_message "Talos.URL" do
      optional :raw_url, :string, 1
      repeated :endpoint, :message, 2, "Talos.IPEndpoint"
      optional :source, :enum, 3, "Talos.URLSource"
      optional :do_not_crawl, :bool, 4
    end
    add_message "Talos.VersionRange" do
      optional :starting, :uint32, 1
      optional :ending, :uint32, 2
    end
    add_message "Talos.VersionMeta" do
      repeated :delta, :message, 1, "Talos.VersionDelta"
    end
    add_message "Talos.VersionDelta" do
      optional :version, :uint32, 1
      repeated :delta_entry, :message, 2, "Talos.VersionDeltaEntry"
    end
    add_message "Talos.VersionDeltaEntry" do
      optional :from_id, :uint32, 1
      optional :to_id, :uint32, 2
    end
    add_message "Talos.ThreatCategory" do
      optional :threat_cat_id, :uint32, 1
      optional :threat_cat_mnemonic, :string, 2
      repeated :desc_short, :message, 3, "Talos.LocalizedString"
      repeated :desc_long, :message, 4, "Talos.LocalizedString"
      optional :vers_avail, :message, 6, "Talos.VersionRange"
      optional :is_avail, :bool, 7
    end
    add_message "Talos.ThreatCategoryMap" do
      repeated :threat_cats, :message, 1, "Talos.ThreatCategory"
      optional :version, :uint32, 2
      optional :default_threat_cat_id, :uint32, 3
      optional :map_is_complete, :bool, 4
      optional :version_meta, :message, 5, "Talos.VersionMeta"
    end
    add_message "Talos.AUPCategory" do
      optional :aup_cat_id, :uint32, 1
      optional :aup_cat_mnemonic, :string, 2
      repeated :desc_short, :message, 3, "Talos.LocalizedString"
      repeated :desc_long, :message, 4, "Talos.LocalizedString"
      optional :vers_avail, :message, 6, "Talos.VersionRange"
      optional :is_avail, :bool, 7
    end
    add_message "Talos.AUPCategoryMap" do
      repeated :aup_cats, :message, 1, "Talos.AUPCategory"
      optional :version, :uint32, 2
      optional :map_is_complete, :bool, 3
      optional :version_meta, :message, 5, "Talos.VersionMeta"
    end
    add_message "Talos.ThreatLevel" do
      optional :threat_level_id, :uint32, 1
      optional :threat_level_mnemonic, :string, 2
      optional :score_lower_bound_x10, :sint32, 3
      optional :score_upper_bound_x10, :sint32, 4
      repeated :desc_short, :message, 5, "Talos.LocalizedString"
      repeated :desc_long, :message, 6, "Talos.LocalizedString"
      optional :vers_avail, :message, 7, "Talos.VersionRange"
      optional :is_avail, :bool, 8
      optional :sort_index, :uint32, 9
    end
    add_message "Talos.ThreatLevelMap" do
      repeated :threat_levels, :message, 1, "Talos.ThreatLevel"
      optional :version, :uint32, 2
      optional :map_is_complete, :bool, 3
      optional :version_meta, :message, 4, "Talos.VersionMeta"
    end
    add_message "Talos.TagMap" do
      repeated :tags, :message, 1, "Talos.Tag"
      optional :version, :uint32, 2
      optional :map_is_complete, :bool, 3
      optional :version_meta, :message, 4, "Talos.VersionMeta"
    end
    add_message "Talos.Tag" do
      optional :tag_id, :uint32, 1
      optional :tag_mnemonic, :string, 2
      repeated :desc_short, :message, 3, "Talos.LocalizedString"
      repeated :desc_long, :message, 4, "Talos.LocalizedString"
      optional :vers_avail, :message, 5, "Talos.VersionRange"
      optional :is_avail, :bool, 6
    end
    add_message "Talos.ReputationRule" do
      optional :rep_rule_id, :uint32, 1
      optional :rule_mnemonic, :string, 2
      repeated :desc_short, :message, 3, "Talos.LocalizedString"
      repeated :desc_long, :message, 4, "Talos.LocalizedString"
      optional :vers_avail, :message, 5, "Talos.VersionRange"
      optional :is_avail, :bool, 6
    end
    add_message "Talos.ReputationRuleMap" do
      repeated :rules, :message, 1, "Talos.ReputationRule"
      optional :version, :uint32, 2
      optional :map_is_complete, :bool, 3
    end
    add_message "Talos.TaxonomyMap" do
      repeated :taxonomies, :message, 1, "Talos.Taxonomy"
      optional :version, :uint32, 2
    end
    add_message "Talos.Taxonomy" do
      optional :taxonomy_id, :uint32, 1
      repeated :valid_fields, :string, 2
      optional :name, :string, 3
      optional :description, :string, 4
      repeated :entries, :message, 5, "Talos.TaxonomyEntry"
      optional :version, :uint32, 6
      optional :version_meta, :message, 7, "Talos.VersionMeta"
      optional :mnemonic, :string, 8
    end
    add_message "Talos.IntelSpecificDescription" do
      optional :intelligence_type_id, :uint32, 1
      repeated :description, :message, 2, "Talos.LocalizedString"
    end
    add_message "Talos.TaxonomyExtRef" do
      optional :url, :string, 1
      optional :external_id, :string, 2
      optional :source, :string, 3
    end
    add_message "Talos.TaxonomyEntry" do
      optional :entry_id, :uint32, 1
      repeated :name, :message, 2, "Talos.LocalizedString"
      repeated :short_name, :message, 3, "Talos.LocalizedString"
      repeated :description, :message, 4, "Talos.LocalizedString"
      repeated :short_description, :message, 5, "Talos.LocalizedString"
      repeated :intel_specific_descriptions, :message, 6, "Talos.IntelSpecificDescription"
      optional :vers_avail, :message, 7, "Talos.VersionRange"
      optional :is_avail, :bool, 8
      repeated :parent_entries, :message, 9, "Talos.TaxonomyRelation"
      repeated :intelligence_type_ids, :uint32, 10
      repeated :external_references, :message, 11, "Talos.TaxonomyExtRef"
      optional :sort_index, :uint32, 12
      optional :mnemonic, :string, 13
    end
    add_message "Talos.TaxonomyRelation" do
      optional :taxonomy_id, :uint32, 1
      optional :taxonomy_entry_id, :uint32, 2
    end
    add_message "Talos.ContextTag" do
      optional :tag_type_id, :uint32, 1
      optional :taxonomy_id, :uint32, 2
      optional :taxonomy_entry_id, :uint32, 3
      optional :tag_val_uint32, :uint32, 4
      optional :tag_val_uint64, :uint64, 5
      optional :tag_val_string, :string, 6
      optional :tag_val_bytes, :bytes, 7
      optional :tag_key_string, :string, 8
      optional :external_id, :string, 9
    end
    add_message "Talos.ContextGroup" do
      optional :taxonomy_id, :uint32, 1
      optional :taxonomy_entry_id, :uint32, 2
      repeated :context_tags, :message, 3, "Talos.ContextTag"
    end
    add_message "Talos.ServiceData" do
      optional :service_name, :string, 1
      optional :message_type, :string, 2
      optional :data, :bytes, 3
    end
    add_message "Talos.EmptyRequest" do
    end
    add_message "Talos.EmptyReply" do
    end
    add_message "Talos.IPAddress" do
      oneof :address do
        optional :ipv4_addr, :fixed32, 1
        optional :ipv6_addr, :bytes, 2
      end
    end
    add_message "Talos.IPAddressRange" do
      optional :ip_start, :message, 1, "Talos.IPAddress"
      optional :ip_end, :message, 2, "Talos.IPAddress"
    end
    add_message "Talos.HTTPHeader" do
      optional :name, :string, 1
      optional :value, :string, 2
    end
    add_enum "Talos.URLSource" do
      value :URL_LOCATION_UNSPECIFIED, 0
      value :URL_LOCATION_PROXY, 1
      value :URL_LOCATION_EMAIL_HEADER, 2
      value :URL_LOCATION_EMAIL_BODY, 3
      value :URL_LOCATION_EMAIL_ATTACHMENT, 4
      value :URL_LOCATION_EMAIL_UNSUBSCRIBE, 5
    end
  end
end

module Talos
  IPConnection = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IPConnection").msgclass
  IPConnection::Direction = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IPConnection.Direction").enummodule
  IPConnection::Protocol = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IPConnection.Protocol").enummodule
  IPEndpoint = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IPEndpoint").msgclass
  IPEndpoint::ConnectionRole = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IPEndpoint.ConnectionRole").enummodule
  SMTPEnvelope = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.SMTPEnvelope").msgclass
  MailData = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.MailData").msgclass
  EmailMailbox = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.EmailMailbox").msgclass
  EmailList = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.EmailList").msgclass
  EmailList::EmailListUnsubPost = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.EmailList.EmailListUnsubPost").enummodule
  EmailHeader = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.EmailHeader").msgclass
  SPFResults = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.SPFResults").msgclass
  SPFResults::ResultType = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.SPFResults.ResultType").enummodule
  DKIMDisposition = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.DKIMDisposition").msgclass
  DKIMDisposition::DKIMCanon = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.DKIMDisposition.DKIMCanon").enummodule
  DMARCDisposition = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.DMARCDisposition").msgclass
  AppInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.AppInfo").msgclass
  GeoCoords = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.GeoCoords").msgclass
  GeoLocation = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.GeoLocation").msgclass
  LocalizedString = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.LocalizedString").msgclass
  URL = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.URL").msgclass
  VersionRange = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.VersionRange").msgclass
  VersionMeta = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.VersionMeta").msgclass
  VersionDelta = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.VersionDelta").msgclass
  VersionDeltaEntry = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.VersionDeltaEntry").msgclass
  ThreatCategory = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ThreatCategory").msgclass
  ThreatCategoryMap = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ThreatCategoryMap").msgclass
  AUPCategory = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.AUPCategory").msgclass
  AUPCategoryMap = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.AUPCategoryMap").msgclass
  ThreatLevel = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ThreatLevel").msgclass
  ThreatLevelMap = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ThreatLevelMap").msgclass
  TagMap = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.TagMap").msgclass
  Tag = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.Tag").msgclass
  ReputationRule = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ReputationRule").msgclass
  ReputationRuleMap = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ReputationRuleMap").msgclass
  TaxonomyMap = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.TaxonomyMap").msgclass
  Taxonomy = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.Taxonomy").msgclass
  IntelSpecificDescription = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IntelSpecificDescription").msgclass
  TaxonomyExtRef = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.TaxonomyExtRef").msgclass
  TaxonomyEntry = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.TaxonomyEntry").msgclass
  TaxonomyRelation = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.TaxonomyRelation").msgclass
  ContextTag = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ContextTag").msgclass
  ContextGroup = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ContextGroup").msgclass
  ServiceData = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.ServiceData").msgclass
  EmptyRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.EmptyRequest").msgclass
  EmptyReply = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.EmptyReply").msgclass
  IPAddress = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IPAddress").msgclass
  IPAddressRange = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.IPAddressRange").msgclass
  HTTPHeader = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.HTTPHeader").msgclass
  URLSource = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Talos.URLSource").enummodule
end
