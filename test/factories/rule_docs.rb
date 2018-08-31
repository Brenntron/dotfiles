FactoryBot.define do
  factory :rule_doc do
    summary                             { 'some pig' }
    impact                              { 'boom' }
    details                             { 'slow roasted bbq' }
    affected_sys                        { 'ribs, loin, hock, shoulder, leg, belly' }
    attack_scenarios                    { 'sneak up on that hog' }
    ease_of_attack                      { 'depends' }
    false_positives                     { 'none' }
    false_negatives                     { 'none' }
    corrective_action                   { 'sweet sweet red sauce' }
    contributors                        { 'Hormel' }
  end
end
