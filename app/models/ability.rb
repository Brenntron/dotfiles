class Ability
  include CanCan::Ability

  def initialize(user_given)
    current_user = user_given || User.new

    # Query database *once*
    roles = current_user.roles
    role_names = roles.pluck(:role)


    can [:read, :update_preferences, :manage_bugzilla_api], User, id: current_user.id
    can [:read], AmpNamingConvention

    # roles are partitioned into org subsets (snort rules, snort escalations, web cat, web rep)
    # the current user can read the user records of other users in their subset.
    can :read, User do |other_user|
      roles.each do |current_user_role|
        other_user.roles.where(org_subset_id: current_user_role.org_subset_id).exists?
      end
    end

    if role_names.include?('super admin')
      can :manage, :rails_c
    end

    # admin role includes developers who maintain the site
    if role_names.include?('admin')
      can :read, :all
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
      can :manage, [Complaint, ComplaintEntry]
    end


    if role_names.include?('webrep manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end
      can [:read, :advanced_search, :named_search, :standard_search, :contains_search, :export_resolution_age_report,
           :resolution_report, :export_per_resolution_report, :export_per_engineer_report, :resolution_age_report,
           :dashboard, :research],
          Dispute
      can :read, [DisputeComment, DisputeEmail, DisputeEmailAttachment, DisputeEntry, Wbrs::ManualWlbl]
      can :manage, [EmailTemplate]
    end

    if role_names.include?('webrep user')
      can :manage, [Dispute, DisputeComment, DisputeEmail, DisputeEmailAttachment,
                    DisputeEntry, EmailTemplate, Wbrs::ManualWlbl, ResolutionMessageTemplate]
    end

    if role_names.include?('amp pattern namer')
      can :manage, AmpNamingConvention
    end

    if role_names.include?('filerep manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end
      can [:create, :update, :read], [FileReputationDispute, DisputeEmail]
      can [:manage], [FileRepComment]
      can :take, FileReputationDispute do |filerep_dispute|
        filerep_dispute.user_id == User.vrtincoming.id
      end

      can :return, FileReputationDispute do |filerep_dispute|
        filerep_dispute.user_id == current_user.id
      end

      can :change_assignee, FileReputationDispute
    end

    if role_names.include?('filerep user')
      can [:create, :update, :read], [FileReputationDispute, DisputeEmail, FileRepComment]
      can [:delete], [FileRepComment]

      can :take, FileReputationDispute do |filerep_dispute|
        filerep_dispute.user_id == User.vrtincoming&.id
      end

      can :return, FileReputationDispute do |filerep_dispute|
        filerep_dispute.user_id == current_user.id
      end
    end

    if role_names.include?('ips escalator manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end

    end

    # 'manager' role is 'ips rule manager', but renaming would break things.
    if role_names.include?('manager')
      can :manage, User do |user| #no delete UI is implemented
        user.ancestors.include?(current_user)
      end
    end
  end
end
