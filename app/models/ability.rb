class Ability
  include CanCan::Ability

  def initialize(user_given)
    current_user = user_given || User.new

    can :read, :all

    if current_user.has_role?('admin')
      can :manage, User
      can :manage, Admin
      can :acknowledge_bug, Bug
    end
    if current_user.has_role?('manager')
      can :manage, User do |user|
        user.ancestors.include?(current_user)
      end
    end
    if current_user.has_role?('committer')
      can [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference, RuleDoc]
      can :publish, Rule
      can :publish_to_bugzilla, Note
      can :update_preferences, User, id: current_user.id
      can :toggle_liberty, Bug
      can :acknowledge_bug, Bug
    end
    if current_user.has_role?('analyst')
      can [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference, RuleDoc]
      can :publish_to_bugzilla, Note
      can :update_preferences, User, id: current_user.id
      can :toggle_liberty, Bug do |bug|
        bug.liberty_clear?
      end
      can :acknowledge_bug, Bug
    end
    if current_user.has_role?('build coordinator')
      cannot [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
      can :update_preferences, User, id: current_user.id
    end
  end
end
