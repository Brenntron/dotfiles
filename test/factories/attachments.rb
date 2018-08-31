FactoryBot.define do
  factory :attachment do
    file_name       { "new.pcap" }
    summary         { "This is an attachment for a bug" }
  end
end
