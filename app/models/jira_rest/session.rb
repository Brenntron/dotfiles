module JiraRest
  class Session 
    attr_accessor :client
       
    def initialize
      @client = JIRA::Client.new(login_options)
    end

    private

    def login_options
      {
        username:     Rails.configuration.jira.username,
        password:     Rails.configuration.jira.password,
        site:         Rails.configuration.jira.host,
        context_path: '',
        auth_type:    :basic
      }
    end
  end
end
