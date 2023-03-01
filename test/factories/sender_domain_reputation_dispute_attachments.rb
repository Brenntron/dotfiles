FactoryBot.define do
  factory :sender_domain_reputation_dispute_attachment do
    sender_domain_reputation_dispute_id { 1 }
    bugzilla_attachment_id              { 197095 }
    file_name                           { 'test file' }
    direct_upload_url                   { 'https://fmd-bugzil-01tst.vrt.sourcefire.com/attachment.cgi?id=197095' }
    size                                { 17008 }
    email_header_data                   { '{"subject":"test subject"}' }
  end
end
