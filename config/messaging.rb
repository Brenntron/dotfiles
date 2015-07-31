#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
  #s.destination :orders, '/queue/Orders'
  #s.filter :some_filter, :only=>:orders
  #s.processor_group :group1, :order_processor

  s.destination :snort_local_rules_test_work, '/queue/RulesUI.Snort.Run.Local.Test.Work'
  s.destination :snort_local_rules_test_result, '/queue/RulesUI.Snort.Run.Local.Test.Result'
  # s.destination :snort_local_rules_result, '/queue/RulesUI.Snort.Run.Local.Result'

end
