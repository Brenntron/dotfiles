class DisputeEmailSerializer < ActiveModel::Serializer
  attributes :id, :dispute_id, :email_headers, :from, :to, :subject, :body, :status,
             :created_at
end