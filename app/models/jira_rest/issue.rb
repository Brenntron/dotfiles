module JiraRest
  class Issue
    attr_accessor :session, :issue

    def initialize(issue_key)
      @session = JiraRest::Session.new
      @issue = @session.client.Issue.find(issue_key)
    end


    def status
      issue.status
    end

    # this will return all available transitions for current issue
    # {"Start progress"=>"11", "Stop progress"=>"31", "Resolve Issue"=>"21", "Close Issue"=>"51"}
    # NOTE if issue will be in "In Progress" status, then only  {"Stop progress"=>"31", "Resolve Issue"=>"21", "Close Issue"=>"51"} will be available
    def available_transitions
      @session.client.Transition.all(:issue => issue).each_with_object({}) do |item, result|
        result[item.name] = item.id;
      end
    end

    # to change issue status we need put string from available_transitions hash
    # for example: change_status("Resolve Issue")
    def change_status(status)
      transition = @issue.transitions.build
      transition_id = available_transitions[status]
      transition.save!("transition" => {"id" => transition_id})
    end

    def create_comment(body)
      @issue.comments.build.save!(:body => body)
    end

    def attachments_data
      @issue.attachments.map do |attachment|
        {
          filename: attachment.filename,
          content: get_attachment_content(attachment).split("\n"),
          type: attachment.mimeType
        }
      end      
    end

    private
    
    def get_attachment_content(attachment)
      @session.client.get(attachment.content).body
    end
  end
end
