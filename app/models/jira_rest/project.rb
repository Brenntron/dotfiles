module JiraRest
  class Project
    attr_accessor :session, :project, :project_key, :issues

    def initialize(project_key)
      @session = JiraRest::Session.new
      @project = @session.client.Project.find(project_key)
    end

    def issues
      @issues ||= JIRA::Resource::Issue.jql(session.client,"PROJECT = '#{project.key}' ORDER BY created DESC")
    end
  end
end
