RailsAdmin.config do |config|
  begin
    build_name = (File.read './public/version.html')
    if /(?<build_num>[0-9\.]+)/ =~ build_name
      build_ary = build_num.split('.')
      version = build_ary[0..2].join('.') #handles 1, 2, 3, and more elements
    else
      version = nil
    end
  rescue
    version = nil
  end

  config.parent_controller = 'ApplicationController'

  ### Popular gems integration

  ## == Devise ==
  # config.authenticate_with do
  #   warden.authenticate! scope: :user
  # end
  # config.current_user_method(&:current_user)

  ## == Cancan ==
  # config.authorize_with :cancan

  config.authorize_with do
    begin
      authorize! :read, Admin
    rescue
      flash[:error] = 'Im sorry, Im afraid I cant let you go there. Admins Only.'
      redirect_to '/'
    end

  end

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  config.show_gravatar = false

  config.main_app_name = ["Analyst Console Escalations", "#{version}"]

  config.included_models = [
      "AbuseRecord",
      "ClusterAssignment",
      "ClusterCategorization",
      "Company",
      "Complaint",
      "ComplaintEntry",
      "ComplaintEntryPreload",
      "ComplaintEntryScreenshot",
      "Customer",
      "DelayedJob",
      "Dispute",
      "DisputeComment",
      "DisputeEmail",
      "DisputeEmailAttachment",
      "DisputeEntry",
      "DisputeEntryPreload",
      "DisputePeek",
      "DisputeRule",
      "DisputeRuleHit",
      "EmailTemplate",
      "EscalationTicket",
      "FileReputationDispute",
      "ImportUrl",
      "JiraImportTask",
      "Platform",
      "ResolutionMessageTemplate",
      "SenderDomainReputationDispute",
      "SenderDomainReputationDisputeAttachment",
      "SenderDomainReputationDisputeComment",
      "SenderDomainReputationEmailTemplate",
      "User",
      "UserApiKey",
      "UserPreference",
      "WebcatCredit",
      'WebCatCluster'
  ]

  config.actions do
    dashboard
    index
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
