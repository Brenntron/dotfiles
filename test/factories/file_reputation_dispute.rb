FactoryBot.define do
  factory :file_reputation_dispute do
    status                  { FileReputationDispute::STATUS_NEW }
    sequence(:file_name)    { |nn| "file_#{nn}.txt" }
    sha256_hash             { Digest::SHA256.hexdigest(file_name) }
    disposition_suggested   { FileReputationDispute::DISPOSITION_MALICIOUS }
  end

  trait :default do
    status                { 'NEW'}
    sha256_hash           { 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928' }
    disposition_suggested {'Malicious'}
  end
end
