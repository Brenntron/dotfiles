#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
  case
    when Rails.env.production?
      s.destination :snort_all_rules_work, '/queue/RulesUI.Snort.Run.All.Work'
      s.destination :snort_all_rules_result, '/queue/RulesUI.Snort.Run.All.Result'
      s.destination :snort_local_rules_work, '/queue/RulesUI.Snort.Run.Local.Work'
      s.destination :snort_local_rules_result, '/queue/RulesUI.Snort.Run.Local.Result'
      s.destination :snort_commit_work, '/queue/RulesUI.Snort.Commit.Work'
      s.destination :snort_commit_result, '/queue/RulesUI.Snort.Commit.Result'
      s.destination :snort_commit_reload, '/queue/RulesUI.Snort.Commit.Reload'
    when Rails.env.staging?
      s.destination :snort_all_rules_stage_work, '/queue/RulesUI.Snort.Run.All.Stage.Work'
      s.destination :snort_all_rules_stage_result, '/queue/RulesUI.Snort.Run.All.Stage.Result'
      s.destination :snort_local_rules_stage_work, '/queue/RulesUI.Snort.Run.Local.Stage.Work'
      s.destination :snort_local_rules_stage_messages, '/queue/RulesUI.Snort.Run.Local.Stage.Messages'
      s.destination :snort_local_rules_stage_result, '/queue/RulesUI.Snort.Run.Local.Stage.Result'
      s.destination :snort_commit_stage_work, '/queue/RulesUI.Snort.Commit.Stage.Work'
      s.destination :snort_commit_stage_result, '/queue/RulesUI.Snort.Commit.Stage.Result'
      s.destination :snort_commit_stage_reload, '/queue/RulesUI.Snort.Commit.Stage.Reload'
    else
      s.destination :snort_all_rules_test_work, '/queue/RulesUI.Snort.Run.All.Test.Work'
      s.destination :snort_all_rules_test_result, '/queue/RulesUI.Snort.Run.All.Test.Result'
      s.destination :snort_local_rules_test_work, '/queue/RulesUI.Snort.Run.Local.Test.Work'
      s.destination :snort_local_rules_test_messages, '/queue/RulesUI.Snort.Run.Local.Test.Messages'
      s.destination :snort_local_rules_test_result, '/queue/RulesUI.Snort.Run.Local.Test.Result'
      s.destination :snort_commit_test_work, '/queue/RulesUI.Snort.Commit.Test.Work'
      s.destination :snort_commit_test_result, '/queue/RulesUI.Snort.Commit.Test.Result'
      s.destination :snort_commit_test_reload, '/queue/RulesUI.Snort.Commit.Test.Reload'
  end
end
