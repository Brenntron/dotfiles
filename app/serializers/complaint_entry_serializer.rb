class ComplaintEntrySerializer < ActiveModel::Serializer
  attributes  :complaint_id, :tag, :subdomain, :domain, :path,:wbrs_score, :url_primary_category, :resolution,
  :resolution_comment, :complaint_entry_resolved_at, :status, :created_at, :updated_at, :sbrs_score, :uri,
  :suggested_disposition, :ip_address, :entry_type, :viewable,  :category, :user_id, :is_important,

end