case
  when Rails.env.production?
    Rails.configuration.publish_local_result = "/queue/RulesUI.Snort.Run.Local.Result"
    Rails.configuration.publish_all_result = "/queue/RulesUI.Snort.Run.All.Result"
    Rails.configuration.subscribe_local_work = "/queue/RulesUI.Snort.Run.Local.Work"
    Rails.configuration.subscribe_all_work = "/queue/RulesUI.Snort.Run.All.Work"

    Rails.configuration.amq_snort_local_work = :snort_local_rules_work
    Rails.configuration.amq_snort_all_work = :snort_all_rules_work
    Rails.configuration.amq_snort_all_result = :snort_all_rules_result
    Rails.configuration.amq_snort_local_result = :snort_local_rules_result

    Rails.configuration.amq_snort_commit_result = :snort_commit_result
  when Rails.env.staging?
    Rails.configuration.publish_local_result = "/queue/RulesUI.Snort.Run.Local.Stage.Result"
    Rails.configuration.publish_all_result = "/queue/RulesUI.Snort.Run.All.Stage.Result"
    Rails.configuration.subscribe_local_work = "/queue/RulesUI.Snort.Run.Local.Stage.Work"
    Rails.configuration.subscribe_all_work = "/queue/RulesUI.Snort.Run.All.Stage.Work"

    Rails.configuration.amq_snort_local = :snort_local_rules_stage_work
    Rails.configuration.amq_snort_all = :snort_all_rules_stage_work
    Rails.configuration.amq_snort_all_result = :snort_all_rules_stage_result
    Rails.configuration.amq_snort_local_result = :snort_local_rules_stage_result

    Rails.configuration.amq_snort_commit_result = :snort_commit_stage_result
  else
    Rails.configuration.publish_local_result = "/queue/RulesUI.Snort.Run.Local.Test.Result"
    Rails.configuration.publish_all_result = "/queue/RulesUI.Snort.Run.All.Test.Result"
    Rails.configuration.subscribe_local_work = "/queue/RulesUI.Snort.Run.Local.Test.Work"
    Rails.configuration.subscribe_all_work = "/queue/RulesUI.Snort.Run.All.Test.Work"

    Rails.configuration.amq_snort_local = :snort_local_rules_test_work
    Rails.configuration.amq_snort_all = :snort_all_rules_test_work
    Rails.configuration.amq_snort_all_result = :snort_all_rules_test_result
    Rails.configuration.amq_snort_local_result = :snort_local_rules_test_result

    Rails.configuration.amq_snort_commit_result = :snort_commit_test_result
end
