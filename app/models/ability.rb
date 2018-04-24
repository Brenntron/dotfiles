class Ability
  include CanCan::Ability

  def initialize(user_given)
    current_user = user_given || User.new


    if current_user.has_role?('admin')
      can :read, :all
      can :manage, [Admin, User]
      can [:read, :acknowledge_bug, :list_research, :list_escalations], Bug
      can :manage, RuleDoc
    end
    if current_user.has_role?('manager')
      can [:list_research, :list_escalations], Bug
      can :manage, User do |user|
        user.ancestors.include?(current_user)
      end
    end
    if current_user.has_role?('escalator')
      can :list_escalations, Bug
    end
    if current_user.has_role?('committer')
      can [:read, :update, :destroy, :create, :list_research, :acknowledge_bug, :toggle_liberty], Bug
      can :manage, [Rule, Attachment, Note, Exploit, Reference, RuleDoc]
      can :publish, Rule
      can :publish_to_bugzilla, Note
      can :update_preferences, User, id: current_user.id
    end
    if current_user.has_role?('analyst')
      can [:read, :update, :destroy, :create, :list_research, :acknowledge_bug], Bug
      can :manage, [Rule, Attachment, Note, Exploit, Reference, RuleDoc]
      can :publish_to_bugzilla, Note
      can :update_preferences, User, id: current_user.id
      can :toggle_liberty, Bug do |bug|
        bug.liberty_clear?
      end
    end
    if current_user.has_role?('build coordinator')
      cannot [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
      can :update_preferences, User, id: current_user.id
    end
  end
end
