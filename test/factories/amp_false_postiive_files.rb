FactoryBot.define do
  factory :amp_false_positive_file do
    sha256                      {"c75ea5bb6d19fd5218dd482859756e95889521bc72d4e6b41c3db2be675a95ee"}
    name                        {"test_file.txt"}
    path                        {"blah/somewhere/blah"}
    download_url                {"idontknow/whatthis/lookslike.html"}
    detection_name              {"notsure"}
    detection_count_within_org  {"1"}
  end
end
