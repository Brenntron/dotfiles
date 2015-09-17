require File.expand_path('../boot', __FILE__)

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

    # Enable this to prevent any ssl verification
    # (we could do this but this is bad... dont do this.)
    # OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

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

    # Rails.env.development? ? config.bugzilla_host = 'bugzillaTest02.vrt.sourcefire.com' : config.bugzilla_host = 'bugzilla.vrt.sourcefire.com' This line should go in production mode
    Rails.env.development? ? config.bugzilla_host = 'bugzillatest02.vrt.sourcefire.com' : config.bugzilla_host = 'bugzillatest02.vrt.sourcefire.com'
    config.bugzilla_domain = 'cisco.com'
    config.snort_rule_path = Rails.root.join('extras', 'snort', 'rules')
    config.osvdb_api_key = '00wJFQuHKue2GRFAiQ0neXcqks'
    Rails.env.development? ? config.cve2x_path = Rails.root.join('extras', 'cve2x_dev.pl') : config.cve2x_path = Rails.root.join('extras', 'cve2x.pl')
    config.rule2yaml_path = Rails.root.join('extras', 'rule2yaml.pl')
    Rails.env.development? ? config.visruleparser_path = Rails.root.join('extras', 'visruleparser_dev.pl') : config.visruleparser_path = Rails.root.join('extras', 'visruleparser.pl')
    config.osvdb_search_url = "http://www.osvdb.org/search/search?search[refid]=DATA"
    config.max_attachment_size = 50000000 # 50MB
    config.job_timeout = 300    # 5 minutes
  end
end
