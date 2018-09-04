
FactoryBot.define do
  sequence(:cve_index_seq) do |nn|
    nn
  end
  factory :reference do
    reference_data                      { 'some data' }
    reference_type_id                   { '1' }

    factory :cve_reference do
      transient do
        year { 2003 + Random.rand(15) }
        index { 100 + generate(:cve_index_seq) }
      end

      reference_type { ReferenceType.cve || FactoryBot.create(:cve_reference_type) }
      reference_data { "#{year}-#{'%04i' % index}" }
    end
  end
end
