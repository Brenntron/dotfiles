all_configs = YAML.load_file(Rails.root.join("config", "config.yml"))
env_config = all_configs[Rails.env]
env_config['bugzilla']

raise "config.yml missing #{Rails.env} section" unless env_config

Rails.configuration.app_name = Rails.application.engine_name.gsub(/_application/,'')

Rails.configuration.api_master_timeout  = env_config.fetch('api_timeout', {}).fetch('timeout', nil) || 20



amp_poke = env_config.fetch('amp_poke', {})
Rails.configuration.amp_poke            = ApiRequester::ApiRequester.config_of(amp_poke)


app_info_config = env_config['app_info']
raise 'config.yml missing app_info section' unless app_info_config
Rails.configuration.app_info        = OpenStruct.new
Rails.configuration.app_info.device_id      = app_info_config['device_id'] || Socket.gethostname
Rails.configuration.app_info.product_family = app_info_config['product_family'] || 'Talos_Web'
Rails.configuration.app_info.product_id     = app_info_config['product_id'] || 'analyst-console-escalations'
Rails.configuration.app_info.product_version =
  begin
    version = app_info_config['product_version']
    unless version.present?
      version = File.open("public/escalations/version.html", "rt") { |file| file.read }.chomp rescue nil
    end
    unless version.present?
      if Rails.env.development? || Rails.env.test?
        Open3.popen3("git symbolic-ref --short HEAD") do |stdin, stdout, stderr, wait_thr|
          version = stdout.read.chomp rescue nil
        end
        # Alternatives are
        # git branch --show-current
        # => also the currenct branch, which might be a better command line.
        # git rev-parse HEAD
        # => the revision hash
      end
    end
    unless version.present?
      version = Rails.env.to_s
    end
    version
  end
Rails.configuration.app_info.client_cert_file = app_info_config['client_cert_file']
Rails.configuration.app_info.pkey_file  = app_info_config['pkey_file']


# The auto resolve section refers to the auto resolve algorithm where different steps may be disabled.
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

Rails.configuration.auto_resolve        = OpenStruct.new
Rails.configuration.auto_resolve.check_complaints = auto_resolve['complaints'] && auto_resolve['complaints']['check']
Rails.configuration.auto_resolve.check_virus_total = auto_resolve['virus_total'] && auto_resolve['virus_total']['check']
Rails.configuration.auto_resolve.check_umbrella = auto_resolve['umbrella'] && auto_resolve['umbrella']['check']
Rails.configuration.auto_resolve.check_matching_disposition = auto_resolve['check_matching_disposition']

beaker_config = env_config['beaker']
raise "config.yml missing beaker section" unless beaker_config
Rails.configuration.beaker              = OpenStruct.new
Rails.configuration.beaker.ca_cert_file = beaker_config['ca_cert_file']
Rails.configuration.beaker.hostport     = beaker_config['hostport']     # identifier hostport from RFC 1738


bls_config = env_config.fetch('bls', {})
raise 'config.yml missing bls section' unless bls_config
Rails.configuration.bls                 = ApiRequester::ApiRequester.config_of(bls_config)


raise "config.yml missing bugzilla section" unless env_config['bugzilla']

Rails.configuration.bugzilla_host       = ENV['Bugzilla_host']   || env_config['bugzilla']['host']
Rails.configuration.bugzilla_api_key    = env_config['bugzilla']['api_key']
Rails.configuration.bugzilla_username   = ENV['Bugzilla_login']  || env_config['bugzilla']['login']
Rails.configuration.bugzilla_password   = ENV['Bugzilla_secret'] || env_config['bugzilla']['password']


raise "config.yml missing cert section" unless env_config['cert']
Rails.configuration.cert_file           = env_config['cert']['vrt'] # bugzilla cert file


elastic_config = env_config.fetch('elastic', nil)
raise 'config.yml missing elastic section' unless elastic_config
Rails.configuration.elastic             = ApiRequester::ApiRequester.config_of(elastic_config)
Rails.configuration.elastic.username    = elastic_config['username']
Rails.configuration.elastic.password    = elastic_config['password']
Rails.configuration.elastic.tls         = true


enrichment_service_config = env_config['enrichment_service']
raise "config.yml missing enrichment_service section" unless enrichment_service_config
Rails.configuration.enrichment_service           = OpenStruct.new
Rails.configuration.enrichment_service.cert_file = enrichment_service_config['cert_file']
Rails.configuration.enrichment_service.key_file  = enrichment_service_config['key_file']
Rails.configuration.enrichment_service.hostport  = enrichment_service_config['hostport']


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


peakebridge_config = env_config.fetch('peakebridge', {})
peakebridge                             = OpenStruct.new
peakebridge.host                        = peakebridge_config['host']
peakebridge.port                        = peakebridge_config['port']
peakebridge.verify_mode                 = peakebridge_config['verify_mode'] || peakebridge_config['tls_mode'] || peakebridge_config['ssl_mode']
peakebridge.uri_base                    = peakebridge_config['uri_base']
peakebridge.ca_cert_file                = peakebridge_config['ca_cert_file']
peakebridge.sources                     = peakebridge_config['sources'] || []
peakebridge.open_timeout = peakebridge_config['timeout'] || Rails.configuration.api_master_timeout
peakebridge.read_timeout = peakebridge_config['timeout'] || Rails.configuration.api_master_timeout
Rails.configuration.peakebridge         = peakebridge


# raise "config.yml missing perl section" unless env_config['perl']
# Rails.configuration.perl_cmd            = env_config['perl']['cmd']
# Rails.configuration.canvas_root         = Rails.root.join(env_config['perl']['canvas_root'])
# Rails.configuration.extras_dir          = Rails.root.join(env_config['perl']['extras_dir'])
# Rails.configuration.visruleparser_path  = Rails.root.join(env_config['perl']['visruleparser_path'])
# Rails.configuration.snort_json_path     = Rails.root.join(env_config['perl']['snort_json_path'])
# Rails.configuration.cve2x_path          = Rails.root.join(env_config['perl']['cve2x_path'])
# Rails.configuration.rule2yaml_path      = Rails.root.join(env_config['perl']['rule2yaml_path'])


rep_api = env_config.fetch('rep_api', nil)
raise 'config.yml missing rep_api section' unless rep_api
Rails.configuration.rep_api             = ApiRequester::ApiRequester.config_of(rep_api)


reversing_labs_config = env_config['reversing_labs']
raise 'config.yml missing ReversingLabs section' unless reversing_labs_config
Rails.configuration.reversing_labs      = ApiRequester::ApiRequester.config_of(reversing_labs_config)


sds_config = env_config.fetch('sds', nil)
raise 'config.yml missing SDS section' unless sds_config
Rails.configuration.sds                 = ApiRequester::ApiRequester.config_of(sds_config)
Rails.configuration.sds.v3_host         = sds_config['v3_host']
Rails.configuration.sds.cert_file       = sds_config['client_cert_file'] || sds_config['cert_file']
Rails.configuration.sds.pkey_file       = sds_config['pkey_file']

talos_intelligence = env_config.fetch('talos_intelligence', {})
Rails.configuration.talos_intelligence  = ApiRequester::ApiRequester.config_of(talos_intelligence)


tess_config = env_config['tess']
raise 'config.yml missing tess section' unless tess_config
Rails.configuration.tess                = ApiRequester::ApiRequester.config_of(tess_config)


threatgrid = env_config.fetch('threatgrid', nil)
raise 'config.yml missing threatgrid section' unless threatgrid
Rails.configuration.threatgrid          = ApiRequester::ApiRequester.config_of(threatgrid)


ticloud = env_config.fetch('ticloud', nil)
raise 'config.yml missing ticloud section' unless ticloud
Rails.configuration.ticloud             = ApiRequester::ApiRequester.config_of(ticloud)


virustotal = env_config.fetch('virustotal', nil)
Rails.configuration.virustotal          = ApiRequester::ApiRequester.config_of(virustotal)
Rails.configuration.virustotal.url      = virustotal['url']
virustotal = env_config.fetch('auto_resolve',{}).fetch('virus_total', nil)
raise 'config.yml missing virus_total section' unless virustotal
Rails.configuration.virustotal.check    = virustotal['check']


guard_rails = env_config.fetch('guard_rails', nil)
Rails.configuration.guard_rails          = ApiRequester::ApiRequester.config_of(guard_rails)


wbrs_config = env_config['wbrs']
raise 'config.yml missing wbrs section' unless wbrs_config
Rails.configuration.wbrs                = ApiRequester::ApiRequester.config_of(wbrs_config)
# TODO convert auth_token to api_key so it is set by config_of method.
Rails.configuration.wbrs.auth_token     = wbrs_config['auth_token']

k2_config = env_config.fetch('k2', nil)
raise 'config.yml missing k2 section' unless k2_config
Rails.configuration.k2                  = ApiRequester::ApiRequester.config_of(k2_config)
Rails.configuration.k2.token            = k2_config['token']

umbrella_fetcher_config = env_config.fetch('umbrella_data_fetcher', nil)
raise 'config.yml missing umbrella_data_fetcher aws section' unless umbrella_fetcher_config
umbrella_aws_config = OpenStruct.new
umbrella_aws_config.aws_access_key_id = umbrella_fetcher_config.dig('aws', 'access_key_id')
umbrella_aws_config.aws_secret_access_key = umbrella_fetcher_config.dig('aws', 'secret_access_key')
Rails.configuration.umbrella_data_fetcher = umbrella_aws_config

ngfw_telemetry_config = env_config.fetch('ngfw_telemetry', nil)
raise 'config.yml missing ngfw_telemetry section' unless ngfw_telemetry_config
ngfw_telemetry_aws_config = OpenStruct.new
ngfw_telemetry_aws_config.aws_access_key_id = ngfw_telemetry_config.dig('aws', 'access_key_id')
ngfw_telemetry_aws_config.aws_secret_access_key = ngfw_telemetry_config.dig('aws', 'secret_access_key')
Rails.configuration.ngfw_telemetry = ngfw_telemetry_aws_config

jira_config = env_config['jira']
raise "config.yml missing jira section" unless jira_config
Rails.configuration.jira                = ApiRequester::ApiRequester.config_of(jira_config)
Rails.configuration.jira.project_key    = jira_config['project_key']
Rails.configuration.jira.token          = jira_config['token']
Rails.configuration.jira.auth_type      = jira_config['auth_type'].to_sym
Rails.configuration.jira.use_cookies    = jira_config['auth_type'] == "cookie"

bast_config = env_config['bast']
raise "config.yml missing bast section" unless bast_config
Rails.configuration.bast              = OpenStruct.new
Rails.configuration.bast.host         = bast_config['host']
Rails.configuration.bast.token        = bast_config['token']