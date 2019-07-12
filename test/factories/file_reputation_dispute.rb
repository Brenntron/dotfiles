FactoryBot.define do
  factory :file_reputation_dispute do
    status                  { FileReputationDispute::STATUS_NEW }
    sequence(:file_name)    { |nn| "file_#{nn}.txt" }
    sha256_hash             { Digest::SHA256.hexdigest(file_name) }
    disposition_suggested   { FileReputationDispute::DISPOSITION_MALICIOUS }
  end

  trait :default do
    status                { FileReputationDispute::STATUS_NEW }
    sha256_hash           { 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928' }
    disposition_suggested {'Malicious'}
  end

  trait :unassigned do
    status                { FileReputationDispute::STATUS_NEW }
    sha256_hash           { 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928' }
    disposition_suggested {'Malicious'}
    user_id               {User.vrtincoming.id}
  end

  trait :resolved do
    status                { FileReputationDispute::STATUS_RESOLVED }
    sha256_hash           { 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928' }
    disposition_suggested {'Malicious'}
  end

  trait :assigned do
    user_id           { User.all.last.id}
    status                { FileReputationDispute::STATUS_ASSIGNED }
    sha256_hash           { 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928' }
    disposition_suggested {'Malicious'}
  end

  trait :assigned_resolved do
    user_id           { User.all.last.id}
    status                { FileReputationDispute::STATUS_RESOLVED }
    sha256_hash           { 'efb947a43bfe6d0812d105f6afdeb9774f4d79254dd48f89f1e95ffdf8732928' }
    disposition_suggested {'Malicious'}
  end
end