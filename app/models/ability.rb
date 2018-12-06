class Ability
  include CanCan::Ability

  def initialize(user_given)
    current_user = user_given || User.new

    # Query database *once*
    roles = current_user.roles
    role_names = roles.pluck(:role)


    can [:read, :update_preferences, :manage_bugzilla_api], User, id: current_user.id

    # roles are partitioned into org subsets (snort rules, snort escalations, web cat, web rep)
    # the current user can read the user records of other users in their subset.
    can :read, User do |other_user|
      roles.each do |current_user_role|
        other_user.roles.where(org_subset_id: current_user_role.org_subset_id).exists?
      end
    end



    # admin role includes developers who maintain the site
    if role_names.include?('admin')
      can :read, :all
      can [:acknowledge_bug], Bug
      can :manage, [Admin, User, Role]
    end


    if role_names.include?('api user')
      # Must be authorized to read API, and read API for V version,
      # and appropriate privileges defined elsewhere in this method,
      # in order to call the API with an API key,
      # Using a Rails session only the appropriate privileges elsewhere are required.
      can :read, ::API
      can :read, ::API::V1
      can :read, ::API::V2
    end


    if role_names.include?('webcat manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end
      can [:read, :show_multiple, :advanced_search, :named_search, :standard_search, :contains_search], Complaint
    end

    if role_names.include?('webcat user')
      can :manage, [Complaint, Attachment, Note]
      can :publish_to_bugzilla, Note
    end


    if role_names.include?('webrep manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end
      can [:read, :advanced_search, :named_search, :standard_search, :contains_search, :export_resolution_age_report,
           :resolution_report, :export_per_resolution_report, :export_per_engineer_report, :resolution_age_report,
           :dashboard, :research],
          Dispute
      can :read, [DisputeComment, DisputeEmail, DisputeEmailAttachment, DisputeEntry,
                  Attachment, Note, Wbrs::ManualWlbl]
      can :manage, [EmailTemplate]
    end

    if role_names.include?('webrep user')
      can :manage, [Dispute, DisputeComment, DisputeEmail, DisputeEmailAttachment, Attachment, Note,
                    DisputeEntry, EmailTemplate, Wbrs::ManualWlbl, ResolutionMessageTemplate]
      can :publish_to_bugzilla, Note
    end

    if role_names.include?('ips escalator manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end

      #:manage allows -- :add_tag, :remove_tag, :add_whiteboard, :remove_whiteboard, :bug_metrics
      can [:manage, :import], EscalationBug
    end

    if role_names.include?('ips escalator')
      can [:manage, :import], EscalationBug
      can :manage, [EscalationLink, Attachment, Note]
      can :create, ResearchBug
      can :publish_to_bugzilla, Note
    end

    # 'manager' role is 'ips rule manager', but renaming would break things.
    if role_names.include?('manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end
      can :read, [ResearchBug, Rule]
    end

    if role_names.include?('committer')
      can [:manage, :acknowledge_bug, :import, :toggle_liberty], ResearchBug do |bug|
        bug.check_permission(current_user)
      end
      can :manage, [EscalationLink, Attachment, Note, Rule]
      can :publish, Rule
      can :publish_to_bugzilla, Note
    end

    if role_names.include?('analyst')
      can [:manage, :acknowledge_bug, :import], ResearchBug do |bug|
        bug.check_permission(current_user)
      end
      can :manage, [Attachment, Note]
      can [:read, :create, :update, :destroy], Rule #CRUD but no publish/commit
      # TODO When implementing escalation bugs re-enable
      # can [:manage, :acknowledge_bug, :import], EscalationBug
      # can :manage, EscalationLink
      can :publish_to_bugzilla, Note
      can :toggle_liberty, ResearchBug do |bug|
        bug.liberty_clear?
      end
    end

    if role_names.include?('build coordinator')
      cannot [:update, :destroy, :create], [Bug, Rule, Attachment, Note]
      can :read, [ResearchBug, Attachment, Note, Rule]
    end
  end
end
