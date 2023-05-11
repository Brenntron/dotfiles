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
