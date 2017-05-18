require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Api
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.middleware.use Rack::Cors do
      allow do
        origins '*'

        resource '/cors',
                 :headers => :any,
                 :methods => [:post],
                 :credentials => true,
                 :max_age => 0

        resource '*',
                 :headers => :any,
                 :methods => [:get, :post, :delete, :put, :options, :head],
                 :max_age => 0
      end
    end

    case Rails.env
      when "development"
        config.ruletest_server = "https://localhost:3000/api_test"
        config.bugzilla_host = 'bugzillaTest02.vrt.sourcefire.com'
        config.visruleparser_path = Rails.root.join('extras', 'visruleparser_dev.pl')
        config.cve2x_path = Rails.root.join('extras', 'cve2x_dev.pl')
        config.rule2yaml_path = Rails.root.join('extras', 'rule2yaml_dev.pl')
        config.amq_host = "localhost"
        config.cert_file = "extras/ssh/ca.pem"
        config.canvas_root = Rails.root.join('extras')
        config.perl_cmd = "/usr/bin/env perl"
        config.svn_cmd = "/usr/bin/env svn"
        config.svn_pwd = ''
        config.rules_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk'
        config.ruledocs_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/rulesdocs/'
      when "staging"
        config.ruletest_server = "https://ruleapitest.vrt.sourcefire.com"
        config.bugzilla_host = 'bugzillaTest02.vrt.sourcefire.com'
        config.visruleparser_path = Rails.root.join('extras', 'visruleparser.pl')
        config.cve2x_path = Rails.root.join('extras', 'cve2x.pl')
        config.rule2yaml_path = Rails.root.join('extras', 'rule2yaml.pl')
        config.amq_host = "mqtest01.vrt.sourcefire.com"
        config.cert_file = "/usr/local/etc/trusted-certificates.pem"
        config.canvas_root = Rails.root.join('extras')
        config.perl_cmd = "/usr/local/bin/perl"
        config.svn_cmd = "/usr/local/bin/svn"
        config.svn_pwd = "qHa8Wvz9cKcu!"
        config.rules_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk'
        config.ruledocs_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/rulesdocs/'
      when "production"
        config.ruletest_server = "https://ruletest.vrt.sourcefire.com"
        config.bugzilla_host = 'bugzilla.vrt.sourcefire.com'
        config.visruleparser_path = Rails.root.join('extras', 'visruleparser.pl')
        config.cve2x_path = Rails.root.join('extras', 'cve2x.pl')
        config.rule2yaml_path = Rails.root.join('extras', 'rule2yaml.pl')
        config.amq_host = "mq.vrt.sourcefire.com"
        config.cert_file = "/usr/local/etc/trusted-certificates.pem"
        config.canvas_root = Rails.root.join('extras') # this may need updating for production depending on where we access CANVAS_CATALOG
        config.perl_cmd = "/usr/local/bin/perl"
        config.svn_cmd = "/usr/local/bin/svn"
        config.rules_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk'
        config.ruledocs_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/rulesdocs/'
      when "test"
        config.ruletest_server = "https://localhost:3000/api_test"
        config.bugzilla_host = 'bugzillaTest02.vrt.sourcefire.com'
        config.visruleparser_path = Rails.root.join('extras', 'visruleparser_dev.pl')
        config.cve2x_path = Rails.root.join('extras', 'cve2x_dev.pl')
        config.rule2yaml_path = Rails.root.join('extras', 'rule2yaml_dev.pl')
        config.amq_host = "localhost"
        config.cert_file = "/System/Library/OpenSSL/certs/ca.pem"
        config.canvas_root = Rails.root.join('extras')
        config.perl_cmd = "/usr/bin/env perl"
        config.svn_cmd = "/usr/bin/env svn"
        config.svn_pwd = ''
        config.rules_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk'
        config.ruledocs_repo_url = 'https://repo-test.vrt.sourcefire.com/svn/rules/trunk/docs/rulesdocs/'
    end
    config.websockets_enabled = "false"
    config.bugzilla_domain = 'cisco.com'
    config.snort_rule_path = Rails.root.join('extras', 'snort', 'rules')
    config.osvdb_api_key = '00wJFQuHKue2GRFAiQ0neXcqks'
    config.osvdb_search_url = "http://www.osvdb.org/search/search?search[refid]=DATA"
    config.max_attachment_size = 50000000 # 50MB
    config.job_timeout = 300    # 5 minutes
    ActiveSupport.halt_callback_chains_on_return_false = false
    config.action_controller.per_form_csrf_tokens = true
    config.ssl_options = { hsts: { subdomains: true } }
  end
end
