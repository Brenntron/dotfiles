class ComplaintSerializer < ActiveModel::Serializer
  attributes  :channel, :status, :description, :added_through, :complaint_assigned_at, :complaint_closed_at, :resolution, :resolution_comment, :region

end