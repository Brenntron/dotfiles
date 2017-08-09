
all_configs = YAML.load_file(Rails.root.join("config", "config.yml"))
env_config = all_configs[Rails.env]

Rails.configuration.amq_host            = env_config['amq']['host']

Rails.configuration.bugzilla_host       = ENV['Bugzilla_host']   || env_config['bugzilla']['host']
Rails.configuration.bugzilla_username   = ENV['Bugzilla_login']  || env_config['bugzilla']['login']
Rails.configuration.bugzilla_password   = ENV['Bugzilla_secret'] || env_config['bugzilla']['password']

Rails.configuration.perl_cmd            = env_config['perl']['cmd']

Rails.configuration.svn_cmd             = env_config['svn']['cmd']
Rails.configuration.svn_pwd             = env_config['svn']['password']
Rails.configuration.rules_repo_url      = env_config['svn']['rules_repo_url']
Rails.configuration.ruledocs_repo_url   = env_config['svn']['ruledocs_repo_url']
Rails.configuration.snort_rule_path     = Rails.root.join(env_config['svn']['snort_rule_path'])

