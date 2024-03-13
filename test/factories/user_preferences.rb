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

    trait :webcat_show_all_columns do
      name { 'WebcatDefaultColumns' }
      value {'{
        "view-ticket-col-cb": "true",
        "view-data-entry-id": "true",
        "view-data-age": "true",
        "view-data-status": "true",
        "view-data-source": "true",
        "view-submitter-col-cb": "true",
        "view-data-org-cb": "true",
        "view-data-name-cb": "true",
        "view-data-email-cb": "true",
        "view-data-platform-cb": "true",
        "view-user-col-cb": "true",
        "view-data-assignee-cb": "true",
        "view-data-reviewer-cb": "true",
        "view-data-sec-reviewer-cb": "true",
        "view-tags-col-cb": "true",
        "view-description-col-cb": "true",
        "view-sugg-col-cb": "true",
        "view-tools-col-cb": "true"
      }'}
    end

  end
end