FactoryBot.define do
  factory :amp_false_positive do
    sha256                    {"c75ea5bb6d19fd5218dd482859756e95889521bc72d4e6b41c3db2be675a95ee"}
    customer                  { FactoryBot.create(:customer)}
    description               { "Just a normal False positive from the amp console" }
    payload                   {"{\"json_payload\":\"This is some kind of blob that will be given to us\"}"}
    amp_false_positive_file   {  FactoryBot.create(:amp_false_positive_file)}
  end
end