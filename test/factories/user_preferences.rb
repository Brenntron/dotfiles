FactoryBot.define do
  factory :user_preference do
    user {User.first}

    trait :webrep_entries_per_page_preference do
      name { "WebRepEntriesPerPage" }
      value { '{"entriesperpage":"100"}'}
    end

    trait :webrep_sort_order_preference do
      name { 'WebRepSortOrder' }
      value { '{"sortorder":[[7,"asc"]]}' }
    end

    trait :webrep_current_page_preference do
      name { 'WebRepCurrentPage' }
      value { '{"currentpage":0}' }
    end

  end
end