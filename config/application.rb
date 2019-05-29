require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AnalystConsoleEscalations
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

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
      when "development", 'profile'
        config.publish_local_result = "/queue/AnalystConsole.Snort.Run.Local.Test.Result"
        config.publish_all_result = "/queue/AnalystConsole.Snort.Run.All.Test.Result"
        config.subscribe_local_work = "/queue/AnalystConsole.Snort.Run.Local.Test.Work"
        config.subscribe_all_work = "/queue/AnalystConsole.Snort.Run.All.Test.Work"

        config.amq_snort_local = :snort_local_rules_test_work
        config.amq_snort_all = :snort_all_rules_test_work
        config.amq_snort_all_result = :snort_all_rules_test_result
        config.amq_snort_local_result = :snort_local_rules_test_result

        config.publish_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Test.Result"
        config.subscribe_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Test"
        config.amq_screenshot_result = :snort_screenshot_test_results
        config.amq_screenshot = :snort_screenshot_test

        config.amq_snort_commit_result = :snort_commit_test_result
      when "freebsd"
        config.publish_local_result = "/queue/AnalystConsole.Snort.Run.Local.Stage.Result"
        config.publish_all_result = "/queue/AnalystConsole.Snort.Run.All.Stage.Result"
        config.subscribe_local_work = "/queue/AnalystConsole.Snort.Run.Local.Stage.Work"
        config.subscribe_all_work = "/queue/AnalystConsole.Snort.Run.All.Stage.Work"
        config.amq_snort_local = :snort_local_rules_stage_work
        config.amq_snort_all = :snort_all_rules_stage_work
        config.amq_snort_all_result = :snort_all_rules_stage_result
        config.amq_snort_local_result = :snort_local_rules_stage_result

        config.publish_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Stage.Result"
        config.subscribe_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Stage"
        config.amq_screenshot_result = :snort_screenshot_test_results
        config.amq_screenshot = :snort_screenshot_test

        config.amq_snort_commit_result = :snort_commit_stage_result
      when "staging"
        config.publish_local_result = "/queue/AnalystConsole.Snort.Run.Local.Stage.Result"
        config.publish_all_result = "/queue/AnalystConsole.Snort.Run.All.Stage.Result"
        config.subscribe_local_work = "/queue/AnalystConsole.Snort.Run.Local.Stage.Work"
        config.subscribe_all_work = "/queue/AnalystConsole.Snort.Run.All.Stage.Work"

        config.amq_snort_local = :snort_local_rules_stage_work
        config.amq_snort_all = :snort_all_rules_stage_work
        config.amq_snort_all_result = :snort_all_rules_stage_result
        config.amq_snort_local_result = :snort_local_rules_stage_result

        config.publish_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Stage.Result"
        config.subscribe_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Stage"
        config.amq_screenshot_result = :snort_screenshot_test_results
        config.amq_screenshot = :snort_screenshot_test

        config.amq_snort_commit_result = :snort_commit_stage_result

      when "production"
        config.publish_local_result = "/queue/AnalystConsole.Snort.Run.Local.Result"
        config.publish_all_result = "/queue/AnalystConsole.Snort.Run.All.Result"
        config.subscribe_local_work = "/queue/AnalystConsole.Snort.Run.Local.Work"
        config.subscribe_all_work = "/queue/AnalystConsole.Snort.Run.All.Work"

        config.amq_snort_local = :snort_local_rules_work
        config.amq_snort_all = :snort_all_rules_work
        config.amq_snort_all_result = :snort_all_rules_result
        config.amq_snort_local_result = :snort_local_rules_result

        config.publish_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Result"
        config.subscribe_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot"
        config.amq_screenshot_result = :snort_screenshot_results
        config.amq_screenshot = :snort_screenshot

        config.amq_snort_commit_result = :snort_commit_result
      when "test"
        config.publish_local_result = "/queue/AnalystConsole.Snort.Run.Local.Test.Result"
        config.publish_all_result = "/queue/AnalystConsole.Snort.Run.All.Test.Result"
        config.subscribe_local_work = "/queue/AnalystConsole.Snort.Run.Local.Test.Work"
        config.subscribe_all_work = "/queue/AnalystConsole.Snort.Run.All.Test.Work"

        config.amq_snort_local = :snort_local_rules_test_work
        config.amq_snort_all = :snort_all_rules_test_work
        config.amq_snort_all_result = :snort_all_rules_test_result
        config.amq_snort_local_result = :snort_local_rules_test_result

        config.publish_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Test.Result"
        config.subscribe_screenshot = "/queue/AnalystConsole.Snort.Run.Screenshot.Test"
        config.amq_screenshot_result = :snort_screenshot_test_results
        config.amq_screenshot = :snort_screenshot_test

        config.amq_snort_commit_result = :snort_commit_test_result
    end

    config.active_job.queue_adapter = :delayed_job

    config.websockets_enabled = "false"
    config.job_timeout = 300    # 5 minutes
    config.action_controller.per_form_csrf_tokens = true
    config.ssl_options = { hsts: { subdomains: true } }
  end
end
