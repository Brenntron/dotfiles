all_configs = YAML.load_file(Rails.root.join("config", "config.yml"))
env_config = all_configs[Rails.env]
env_config['bugzilla']

raise "config.yml missing #{Rails.env} section" unless env_config

Rails.configuration.app_name = Rails.application.engine_name.gsub(/_application/,'')

Rails.configuration.api_master_timeout  = env_config.fetch('api_timeout', {}).fetch('timeout', nil) || 20

amp_poke = env_config.fetch('amp_poke', {})
Rails.configuration.amp_poke            = ApiRequester::ApiRequester.config_of(amp_poke)

raise "config.yml missing amq section" unless env_config['amq']
Rails.configuration.amq_host            = env_config['amq']['host']


auto_resolve = env_config['auto_resolve']
raise "config.yml missing auto_resolve section" unless auto_resolve
complaints                              = OpenStruct.new
if auto_resolve['complaints']
  complaints.check                      = auto_resolve['complaints']['check']
else
  complaints.check                      = false
end
Rails.configuration.complaints          = complaints

umbrella = env_config.fetch('auto_resolve',{}).fetch('umbrella', nil)
raise 'config.yml missing umbrella section' unless umbrella
Rails.configuration.umbrella            = ApiRequester::ApiRequester.config_of(umbrella)
Rails.configuration.umbrella.check      = umbrella['check'] || false
Rails.configuration.umbrella.url        = umbrella['url']

raise "config.yml missing bugzilla section" unless env_config['bugzilla']

Rails.configuration.bugzilla_host       = ENV['Bugzilla_host']   || env_config['bugzilla']['host']
Rails.configuration.bugzilla_api_key    = env_config['bugzilla']['api_key']
Rails.configuration.bugzilla_username   = ENV['Bugzilla_login']  || env_config['bugzilla']['login']
Rails.configuration.bugzilla_password   = ENV['Bugzilla_secret'] || env_config['bugzilla']['password']

raise "config.yml missing cert section" unless env_config['cert']
Rails.configuration.cert_file           = env_config['cert']['vrt']


# New apirequester interface
peakebridge_config = env_config.fetch('peakebridge', {})
raise "config.yml missing peakebridge section" if peakebridge_config.empty?
Rails.configuration.peakebridge         = ApiRequester::ApiRequester.config_of(peakebridge_config)
pb_sources = peakebridge_config.fetch('sources', {})
Rails.configuration.peakebridge.sources = pb_sources


raise "config.yml missing perl section" unless env_config['perl']
Rails.configuration.perl_cmd            = env_config['perl']['cmd']
Rails.configuration.canvas_root         = Rails.root.join(env_config['perl']['canvas_root'])
Rails.configuration.extras_dir          = Rails.root.join(env_config['perl']['extras_dir'])
Rails.configuration.visruleparser_path  = Rails.root.join(env_config['perl']['visruleparser_path'])
Rails.configuration.snort_json_path     = Rails.root.join(env_config['perl']['snort_json_path'])
Rails.configuration.cve2x_path          = Rails.root.join(env_config['perl']['cve2x_path'])
Rails.configuration.rule2yaml_path      = Rails.root.join(env_config['perl']['rule2yaml_path'])

# New apirequester interface
rep_api = env_config.fetch('rep_api', nil)
raise 'config.yml missing rep_api section' unless rep_api
Rails.configuration.rep_api             = ApiRequester::ApiRequester.config_of(rep_api)

# TODO Check if unused
raise "config.yml missing ruletest section" unless env_config['ruletest']
Rails.configuration.ruletest_server     = env_config['ruletest']['url']


sds_config = env_config.fetch('sds', nil)
raise 'config.yml missing SDS section' unless sds_config
Rails.configuration.sds                 = ApiRequester::ApiRequester.config_of(sds_config)
Rails.configuration.sds.pkey_file       = sds_config['pkey_file']


# TODO Check if unused
Rails.configuration.snort_doc_max_fails = env_config['snort_doc_max_fails'] || 3

# TODO Check if unused
# New apirequester interface
snort_org_config = env_config.fetch('snort_org', nil)
raise 'config.yml missing snort_org section' unless snort_org_config
Rails.configuration.snort_org           = ApiRequester::ApiRequester.config_of(snort_org_config)

# TODO Check if unused
raise "config.yml missing svn section" unless env_config['svn']
Rails.configuration.svn_cmd             = env_config['svn']['cmd']
Rails.configuration.svn_pwd             = env_config['svn']['password']
Rails.configuration.rules_repo_url      = env_config['svn']['rules_repo_url']
Rails.configuration.ruledocs_repo_url   = env_config['svn']['ruledocs_repo_url']
Rails.configuration.snort_rule_path     = Rails.root.join(env_config['svn']['snort_rule_path'])

talos_intelligence = env_config.fetch('talos_intelligence', {})
Rails.configuration.talos_intelligence  = ApiRequester::ApiRequester.config_of(talos_intelligence)


wbrs_config = env_config['wbrs']
raise 'config.yml missing wbrs section' unless wbrs_config
Rails.configuration.wbrs                = ApiRequester::ApiRequester.config_of(wbrs_config)
# TODO convert auth_token to api_key so it is set by config_of method.
Rails.configuration.wbrs.auth_token     = wbrs_config['auth_token']

# New apirequester interface
xbrs_config = env_config.fetch('xbrs', nil)
raise 'config.yml missing xbrs section' unless xbrs_config
Rails.configuration.xbrs                = ApiRequester::ApiRequester.config_of(xbrs_config)
Rails.configuration.xbrs.consumer_key   = xbrs_config['consumer_key']


virustotal = env_config.fetch('auto_resolve',{}).fetch('virus_total', nil)
raise 'config.yml missing virus_total section' unless virustotal
Rails.configuration.virustotal          = ApiRequester::ApiRequester.config_of(virustotal)
Rails.configuration.virustotal.check    = virustotal['check']
Rails.configuration.virustotal.url      = virustotal['url']

# New apirequester interface
bls_config = env_config.fetch('bls', {})
raise 'config.yml missing bls section' unless bls_config
Rails.configuration.bls                 = ApiRequester::ApiRequester.config_of(bls_config)

file_reputation_sandbox = env_config['file_reputation_sandbox']
raise 'config.yml missing file reputation sandbox section' unless file_reputation_sandbox
Rails.configuration.file_reputation_sandbox          = ApiRequester::ApiRequester.config_of(file_reputation_sandbox)
sandbox_api_keys = file_reputation_sandbox.fetch('api_keys', {})
sandbox_api_keys[FileReputationDispute::SANDBOX_KEY_AC_REFRESH] ||=
    sandbox_api_keys[FileReputationDispute::SANDBOX_KEY_AC_FORM]
Rails.configuration.file_reputation_sandbox.api_keys = sandbox_api_keys

reversing_labs_config = env_config['reversing_labs']
raise 'config.yml missing ReversingLabs section' unless reversing_labs_config
Rails.configuration.reversing_labs      = ApiRequester::ApiRequester.config_of(reversing_labs_config)

magic_api_config = env_config['magic_api']
raise 'config.yml missing MAgic section' unless magic_api_config
Rails.configuration.magic_api           = ApiRequester::ApiRequester.config_of(magic_api_config)

threatgrid = env_config.fetch('threatgrid', nil)
raise 'config.yml missing threatgrid section' unless threatgrid
Rails.configuration.threatgrid          = ApiRequester::ApiRequester.config_of(threatgrid)

ticloud = env_config.fetch('ticloud', nil)
raise 'config.yml missing ticloud section' unless ticloud
Rails.configuration.ticloud             = ApiRequester::ApiRequester.config_of(ticloud)

# New apirequester interface
elastic_config = env_config.fetch('elastic', nil)
raise 'config.yml missing elastic section' unless elastic_config
Rails.configuration.elastic             = ApiRequester::ApiRequester.config_of(elastic_config)
Rails.configuration.elastic.username    = elastic_config['username']
Rails.configuration.elastic.password    = elastic_config['password']
Rails.configuration.elastic.tls         = true
