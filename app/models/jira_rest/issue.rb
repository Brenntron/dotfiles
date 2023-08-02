module JiraRest
  class Issue
    DONE_TRANSITION = 'Resolve issue'
    CLOSE_COMMENT = <<~HEREDOC
      The review of all valid URLs from this ticket has been completed.
      Any added or updated categorizations should appear in the next 24 hours.
      If there are additional URLs that you would like reviewed, please file a new ticket.
    HEREDOC
        
    attr_accessor :issue

    def initialize(issue_key)
      @issue = JiraRest::Session.connection.Issue.find(issue_key)
    end

    def status
      issue.status
    end

    # this will return all available transitions for current issue
    # {"Start progress"=>"11", "Stop progress"=>"31", "Resolve Issue"=>"21", "Close Issue"=>"51"}
    # NOTE if issue will be in "In Progress" status, then only  {"Stop progress"=>"31", "Resolve Issue"=>"21", "Close Issue"=>"51"} will be available
  
    def available_transitions
      Rails.cache.fetch('jira_available_transitions') do
        JiraRest::Session.connection.Transition.all(:issue => issue).each_with_object({}) do |item, result|
          result[item.name] = item.id
        end
      end
    end

    # to change issue status we need put string from available_transitions hash
    # for example: change_status("Resolve Issue")
    def change_status(status)
      transition = @issue.transitions.build
      transition_id = available_transitions[status]
      transition.save!('transition' => { 'id' => transition_id })
    end

    def close_issue
      change_status(DONE_TRANSITION)
      create_comment(CLOSE_COMMENT)
    end

    def create_comment(body)
      @issue.comments.build.save!(:body => body)
    end

    def attachments_data
      @issue.attachments.map do |attachment|
        {
          filename: attachment.filename,
          content: get_attachment_content(attachment),
          type: attachment.mimeType
        }
      end
    end

    private

    def get_attachment_content(attachment)
      case attachment.mimeType
      when 'text/csv'
        CSV.parse(JiraRest::Session.connection.get(attachment.content).body)
      else
        JiraRest::Session.connection.get(attachment.content).body.split('\n')
      end
    end
  end
end
