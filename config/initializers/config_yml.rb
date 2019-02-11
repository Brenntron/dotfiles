
all_configs = YAML.load_file(Rails.root.join("config", "config.yml"))
env_config = all_configs[Rails.env]
raise "config.yml missing #{Rails.env} section" unless env_config

Rails.configuration.app_name = Rails.application.engine_name.gsub(/_application/,'')

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

umbrella                                = OpenStruct.new
if auto_resolve['umbrella']
  umbrella.check                        = auto_resolve['umbrella']['check']
  umbrella.url                          = auto_resolve['umbrella']['url']
  umbrella.api_key                      = auto_resolve['umbrella']['api_key']
else
  umbrella.check                        = false
end
Rails.configuration.umbrella            = umbrella



raise "config.yml missing bugzilla section" unless env_config['bugzilla']
Rails.configuration.bugzilla_host       = ENV['Bugzilla_host']   || env_config['bugzilla']['host']
Rails.configuration.bugzilla_username   = ENV['Bugzilla_login']  || env_config['bugzilla']['login']
Rails.configuration.bugzilla_password   = ENV['Bugzilla_secret'] || env_config['bugzilla']['password']

raise "config.yml missing cert section" unless env_config['cert']
Rails.configuration.cert_file           = env_config['cert']['vrt']


peakebridge_config = env_config['peakebridge']
raise "config.yml missing peakebridge section" unless peakebridge_config
peakebridge                             = OpenStruct.new
peakebridge.host                        = peakebridge_config['host']
peakebridge.port                        = peakebridge_config['port']
peakebridge.verify_mode                 = peakebridge_config['verify_mode'] || peakebridge_config['tls_mode'] || peakebridge_config['ssl_mode']
peakebridge.uri_base                    = peakebridge_config['uri_base']
peakebridge.ca_cert_file                = peakebridge_config['ca_cert_file']
peakebridge.sources                     = peakebridge_config['sources'] || []
Rails.configuration.peakebridge         = peakebridge


raise "config.yml missing perl section" unless env_config['perl']
Rails.configuration.perl_cmd            = env_config['perl']['cmd']
Rails.configuration.canvas_root         = Rails.root.join(env_config['perl']['canvas_root'])
Rails.configuration.extras_dir          = Rails.root.join(env_config['perl']['extras_dir'])
Rails.configuration.visruleparser_path  = Rails.root.join(env_config['perl']['visruleparser_path'])
Rails.configuration.snort_json_path     = Rails.root.join(env_config['perl']['snort_json_path'])
Rails.configuration.cve2x_path          = Rails.root.join(env_config['perl']['cve2x_path'])
Rails.configuration.rule2yaml_path      = Rails.root.join(env_config['perl']['rule2yaml_path'])

# byebug
rep_api = env_config['rep_api']
raise 'config.yml missing rep_api section' unless rep_api
Rails.configuration.rep_api                = OpenStruct.new
Rails.configuration.rep_api.host           = rep_api['host']
Rails.configuration.rep_api.port           = rep_api['port']
Rails.configuration.rep_api.verify_mode    = rep_api['verify_mode'] || rep_api['tls_mode']
Rails.configuration.rep_api.ca_cert_file   = rep_api['ca_cert_file']
Rails.configuration.rep_api.gssnegotiate   = rep_api['gssnegotiate']


raise "config.yml missing ruletest section" unless env_config['ruletest']
Rails.configuration.ruletest_server     = env_config['ruletest']['url']

sds_config = env_config['sds']
Rails.configuration.sds                 = OpenStruct.new
if sds_config
  Rails.configuration.sds.host          = sds_config['host']
  Rails.configuration.sds.cert_file     = sds_config['cert_file']
  Rails.configuration.sds.pkey_file     = sds_config['pkey_file']
  Rails.configuration.sds.user          = sds_config['user']
  Rails.configuration.sds.pass          = sds_config['pass']
end

Rails.configuration.snort_doc_max_fails = env_config['snort_doc_max_fails'] || 3

snort_org_config = env_config['snort_org']
raise 'config.yml missing snort_org section' unless snort_org_config
Rails.configuration.snort_org           = OpenStruct.new
if env_config['snort_org']
  Rails.configuration.snort_org.host      = snort_org_config['host']
  Rails.configuration.snort_org.port      = snort_org_config['port']
  Rails.configuration.snort_org.api_key   = snort_org_config['api_key']
end

raise "config.yml missing svn section" unless env_config['svn']
Rails.configuration.svn_cmd             = env_config['svn']['cmd']
Rails.configuration.svn_pwd             = env_config['svn']['password']
Rails.configuration.rules_repo_url      = env_config['svn']['rules_repo_url']
Rails.configuration.ruledocs_repo_url   = env_config['svn']['ruledocs_repo_url']
Rails.configuration.snort_rule_path     = Rails.root.join(env_config['svn']['snort_rule_path'])


wbrs_config = env_config['wbrs']
raise 'config.yml missing wbrs section' unless wbrs_config
Rails.configuration.wbrs                = OpenStruct.new
Rails.configuration.wbrs.host           = wbrs_config['host']
Rails.configuration.wbrs.port           = wbrs_config['port']
Rails.configuration.wbrs.verify_mode    = wbrs_config['verify_mode'] || wbrs_config['tls_mode']
Rails.configuration.wbrs.ca_cert_file   = wbrs_config['ca_cert_file']
Rails.configuration.wbrs.gssnegotiate   = wbrs_config['gssnegotiate']
Rails.configuration.wbrs.auth_token     = wbrs_config['auth_token']

xbrs_config = env_config['xbrs']
raise 'config.yml missing xbrs section' unless xbrs_config
Rails.configuration.xbrs                = OpenStruct.new
Rails.configuration.xbrs.host           = xbrs_config['host']
Rails.configuration.xbrs.port           = xbrs_config['port']
Rails.configuration.xbrs.verify_mode    = xbrs_config['verify_mode'] || xbrs_config['tls_mode']
Rails.configuration.xbrs.gssnegotiate   = xbrs_config['gssnegotiate']

raise 'config.yml missing virus_total section' unless env_config['virustotal']
virus_total                             = OpenStruct.new
virus_total.check                       = auto_resolve['virus_total']['check']
virus_total.url                         = env_config['virustotal']['url']
virus_total.api_key                     = env_config['virustotal']['api_key']
Rails.configuration.virus_total         = virus_total

virustotal = env_config.fetch('virustotal', {})
Rails.configuration.virustotal          = OpenStruct.new
Rails.configuration.virustotal.host     = virustotal['host']
Rails.configuration.virustotal.port     = virustotal['port']
Rails.configuration.virustotal.api_key  = virustotal['api_key']

bls_config = env_config['bls']
raise 'config.yml missing bls section' unless bls_config
Rails.configuration.bls                = OpenStruct.new
Rails.configuration.bls.host           = bls_config['host']
Rails.configuration.bls.port           = bls_config['port']

