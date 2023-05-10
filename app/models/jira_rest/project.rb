module JiraRest
  class Project
    URLS_FIELD_NAME = 'URL(s)'.freeze
    PLATFORM_FIELD = 'Platform'.freeze

    attr_accessor :session, :project, :project_key, :issues

    def initialize(project_key)
      @session = JiraRest::Session.new
      @project = @session.client.Project.find(project_key)
    end

    def issues(filters=[])
      filters = filters.map { |m| "AND #{m}" }.join(' ')
      @issues ||= JIRA::Resource::Issue.jql(session.client, "PROJECT = '#{project.key}' #{filters} ORDER BY created DESC")
    end

    # This method retrieves the IDs of custom fields from Jira issue data,
    def custom_fields
      Rails.cache.fetch('jira_custom_fields') do
        session.client.Field.all.each_with_object({}) do |field, result|
          case field.name
          when URLS_FIELD_NAME
            result[:urls] = field.id
          when PLATFORM_FIELD
            result[:platform] = field.id
          else
            result[field.name] = field.id
          end
        end
      end
    end
  end
end
