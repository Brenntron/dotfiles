FactoryBot.define do
  factory :bug do
    sequence :bugzilla_id do |nn|
      111000 + nn
    end
    state           { 'OPEN' }
    summary         { 'Summary for testing' }
    product         { 'Research' }
    component       { 'Snort Rules' }
    version         { '2.5.2' }
    description     { 'Description for testing' }

    factory :open_bug do
      # Yes this is currently the default, but a factory specifically making an open bug.
      state         { 'OPEN' }
    end

    trait :new_bug do
      state         { 'NEW' }
      status        { 'NEW' }
      resolution    { 'OPEN' }
    end

    trait :assigned_bug do
      state         { 'ASSIGNED' }
      status        { 'ASSIGNED' }
      resolution    { 'OPEN' }
    end

    trait :open_bug do
      state         { 'OPEN' }
      status        { 'OPEN' }
      resolution    { 'OPEN' }
    end

    trait :reopened_bug do
      state         { 'REOPENED' }
      status        { 'REOPENED' }
      resolution    { 'OPEN' }
    end

    trait :pending_bug do
      state         { 'PENDING' }
      status        { 'RESOLVED' }
      resolution    { 'PENDING' }
    end

    trait :fixed_bug do
      state         { 'FIXED' }
      status        { 'RESOLVED' }
      resolution    { 'FIXED' }
    end

    trait :completed_bug do
      state         { 'COMPLETED' }
      status        { 'RESOLVED' }
      resolution    { 'COMPLETED' }
    end

    factory :research_bug, parent: :bug, class: 'ResearchBug' do
      product       { 'Research' }
      component     { 'Snort Rules' }
    end

    factory :escalation_bug, parent: :bug, class: 'EscalationBug' do
      product       { 'Escalations' }
      component     { 'TAC' }
    end
  end
end
