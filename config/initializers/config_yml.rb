
all_configs = YAML.load_file(Rails.root.join("config", "config.yml"))
env_config = all_configs[Rails.env]
raise "config.yml missing #{Rails.env} section" unless env_config

raise "config.yml missing amq section" unless env_config['amq']
Rails.configuration.amq_host            = env_config['amq']['host']



raise "config.yml missing bugzilla section" unless env_config['bugzilla']
Rails.configuration.bugzilla_host       = ENV['Bugzilla_host']   || env_config['bugzilla']['host']
Rails.configuration.bugzilla_username   = ENV['Bugzilla_login']  || env_config['bugzilla']['login']
Rails.configuration.bugzilla_password   = ENV['Bugzilla_secret'] || env_config['bugzilla']['password']

raise "config.yml missing cert section" unless env_config['cert']
Rails.configuration.cert_file           = env_config['cert']['vrt']

peakebridge                             = OpenStruct.new
if env_config['peakebridge']
  peakebridge.host                        = env_config['peakebridge']['host']
  peakebridge.port                        = env_config['peakebridge']['port']
  peakebridge.ssl                         = env_config['peakebridge']['ssl']
  peakebridge.uri_base                    = env_config['peakebridge']['uri_base']
  peakebridge.sources                     = env_config['peakebridge']['sources'] || []
end
Rails.configuration.peakebridge         = peakebridge

raise "config.yml missing perl section" unless env_config['perl']
Rails.configuration.perl_cmd            = env_config['perl']['cmd']
Rails.configuration.canvas_root         = Rails.root.join(env_config['perl']['canvas_root'])
Rails.configuration.extras_dir          = Rails.root.join(env_config['perl']['extras_dir'])
Rails.configuration.visruleparser_path  = Rails.root.join(env_config['perl']['visruleparser_path'])
Rails.configuration.snort_json_path     = Rails.root.join(env_config['perl']['snort_json_path'])
Rails.configuration.cve2x_path          = Rails.root.join(env_config['perl']['cve2x_path'])
Rails.configuration.rule2yaml_path      = Rails.root.join(env_config['perl']['rule2yaml_path'])

raise "config.yml missing ruletest section" unless env_config['ruletest']
Rails.configuration.ruletest_server     = env_config['ruletest']['url']

Rails.configuration.snort_doc_max_fails = env_config['snort_doc_max_fails'] || 3

Rails.configuration.snort_org           = OpenStruct.new
if env_config['snort_org']
  Rails.configuration.snort_org.host      = env_config['snort_org']['host']
  Rails.configuration.snort_org.port      = env_config['snort_org']['port']
  Rails.configuration.snort_org.api_key   = env_config['snort_org']['api_key']
end

raise "config.yml missing svn section" unless env_config['svn']
Rails.configuration.svn_cmd             = env_config['svn']['cmd']
Rails.configuration.svn_pwd             = env_config['svn']['password']
Rails.configuration.rules_repo_url      = env_config['svn']['rules_repo_url']
Rails.configuration.ruledocs_repo_url   = env_config['svn']['ruledocs_repo_url']
Rails.configuration.snort_rule_path     = Rails.root.join(env_config['svn']['snort_rule_path'])

