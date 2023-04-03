module JiraRest
  class Project
    attr_accessor :session, :project, :project_key, :issues

    def initialize(project_key)
      @session = JiraRest::Session.new
      @project = @session.client.Project.find(project_key)
    end

    def issues(filters=[])
      filters = filters.map {|m| "AND #{m}"}.join(" ")
      @issues ||= JIRA::Resource::Issue.jql(session.client,"PROJECT = '#{project.key}' #{filters} ORDER BY created DESC")
    end
  end
end
