FactoryBot.define do
  factory :file_reputation_dispute do
    status                  { FileReputationDispute::STATUS_NEW }
    sequence(:file_name)    { |nn| "file_#{nn}.txt" }
    sha256_hash             { Digest::SHA256.hexdigest(file_name) }
    disposition_suggested   { FileReputationDispute::DISPOSITION_MALICIOUS }
  end
end
