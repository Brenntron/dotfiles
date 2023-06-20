module JiraRest
  class Session 
    include Singleton
    attr_accessor :client

    def self.connection
      instance.client
    end
       
    def initialize
      @client = JIRA::Client.new(login_options)
    end

    def self.health_check
      health_report = {}

      times_to_try = 3
      times_tried = 0
      times_successful = 0
      times_failed = 0
      is_healthy = false

      (1..times_to_try).each do |i|
        begin
          if JiraRest::Session.connection.Project.find(Rails.configuration.jira.project_key).present?
            times_successful += 1
          else
            times_failed += 1
          end
          times_tried += 1
        rescue
          times_failed += 1
          times_tried += 1
        end

      end

      if times_successful > times_failed
        is_healthy = true
      end

      health_report[:times_tried] = times_tried
      health_report[:times_successful] = times_successful
      health_report[:times_failed] = times_failed
      health_report[:is_healthy] = is_healthy

      health_report
    end

    private

    def login_options
      {
        default_headers: {authorization: "Bearer #{Rails.configuration.jira.token}"},
        site:         Rails.configuration.jira.host,
        context_path: '',
        auth_type:    Rails.configuration.jira.auth_type,
      }
    end
  end
end
