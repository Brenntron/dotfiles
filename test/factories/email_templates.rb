FactoryGirl.define do
  factory :email_template do
    template_name 'PSB'
    body "Our worldwide sensor network indicates that spam originated from IP (x.x.x.x) as recently as xx-xx-xx ."
  end
end