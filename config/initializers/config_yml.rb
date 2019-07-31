
all_configs = YAML.load_file(Rails.root.join("config", "config.yml"))
env_config = all_configs[Rails.env]
raise "config.yml missing #{Rails.env} section" unless env_config

Rails.configuration.app_name = Rails.application.engine_name.gsub(/_application/,'')

amp_poke = env_config.fetch('amp_poke', {})
Rails.configuration.amp_poke            = ApiRequester::ApiRequester.config_of(amp_poke)


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



bls_config = env_config['bls']
raise 'config.yml missing bls section' unless bls_config
Rails.configuration.bls                = OpenStruct.new
Rails.configuration.bls.host           = bls_config['host']
Rails.configuration.bls.port           = bls_config['port']


raise "config.yml missing bugzilla section" unless env_config['bugzilla']
Rails.configuration.bugzilla_host       = ENV['Bugzilla_host']   || env_config['bugzilla']['host']
Rails.configuration.bugzilla_api_key    = env_config['bugzilla']['api_key']
Rails.configuration.bugzilla_username   = ENV['Bugzilla_login']  || env_config['bugzilla']['login']
Rails.configuration.bugzilla_password   = ENV['Bugzilla_secret'] || env_config['bugzilla']['password']


raise "config.yml missing cert section" unless env_config['cert']
Rails.configuration.cert_file           = env_config['cert']['vrt']


elastic_config = env_config['elastic']
raise 'config.yml missing elastic section' unless elastic_config
Rails.configuration.elastic              = OpenStruct.new
Rails.configuration.elastic.host         = elastic_config['host']
Rails.configuration.elastic.port         = elastic_config['port']
Rails.configuration.elastic.verify_mode  = elastic_config['verify_mode']
Rails.configuration.elastic.ca_cert_file = elastic_config['ca_cert_file']
Rails.configuration.elastic.username     = elastic_config['username']
Rails.configuration.elastic.password     = elastic_config['password']
Rails.configuration.elastic.tls          = true


file_reputation_sandbox = env_config['file_reputation_sandbox']
raise 'config.yml missing file reputation sandbox section' unless file_reputation_sandbox
Rails.configuration.file_reputation_sandbox        = ApiRequester::ApiRequester.config_of(file_reputation_sandbox)
sandbox_api_keys = file_reputation_sandbox.fetch('api_keys', {})
sandbox_api_keys[FileReputationDispute::SANDBOX_KEY_AC_REFRESH] ||=
    sandbox_api_keys[FileReputationDispute::SANDBOX_KEY_AC_FORM]
Rails.configuration.file_reputation_sandbox.api_keys = sandbox_api_keys


magic_api_config = env_config['magic_api']
raise 'config.yml missing MAgic section' unless magic_api_config
Rails.configuration.magic_api           = ApiRequester::ApiRequester.config_of(magic_api_config)


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


rep_api = env_config['rep_api']
raise 'config.yml missing rep_api section' unless rep_api
Rails.configuration.rep_api                = OpenStruct.new
Rails.configuration.rep_api.host           = rep_api['host']
Rails.configuration.rep_api.port           = rep_api['port']
Rails.configuration.rep_api.verify_mode    = rep_api['verify_mode'] || rep_api['tls_mode']
Rails.configuration.rep_api.ca_cert_file   = rep_api['ca_cert_file']
Rails.configuration.rep_api.gssnegotiate   = rep_api['gssnegotiate']


sds_config = env_config['sds']
Rails.configuration.sds                 = OpenStruct.new
if sds_config
  Rails.configuration.sds.host          = sds_config['host']
  Rails.configuration.sds.cert_file     = sds_config['cert_file']
  Rails.configuration.sds.pkey_file     = sds_config['pkey_file']
  Rails.configuration.sds.user          = sds_config['user']                    # TODO unused?
  Rails.configuration.sds.pass          = sds_config['pass']                    # TODO unused?
end


wbrs_config = env_config['wbrs']
raise 'config.yml missing wbrs section' unless wbrs_config
Rails.configuration.wbrs                = ApiRequester::ApiRequester.config_of(wbrs_config)
# TODO convert auth_token to api_key so it is set by config_of method.
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


reversing_labs_config = env_config['reversing_labs']
raise 'config.yml missing ReversingLabs section' unless reversing_labs_config
Rails.configuration.reversing_labs      = ApiRequester::ApiRequester.config_of(reversing_labs_config)


threatgrid = env_config.fetch('threatgrid', {})
raise 'config.yml missing threatgrid section' unless threatgrid
Rails.configuration.threatgrid          = ApiRequester::ApiRequester.config_of(threatgrid)


ticloud = env_config.fetch('ticloud', {})
raise 'config.yml missing ticloud section' unless ticloud
Rails.configuration.ticloud             = ApiRequester::ApiRequester.config_of(ticloud)

