FactoryBot.define do
  factory :cluster_categorization do
    category_ids { [1,2].to_json }
  end
end
