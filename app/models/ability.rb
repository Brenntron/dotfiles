class Ability
  include CanCan::Ability

  def initialize(user_given)
    current_user = user_given || User.new

    # Query database *once*
    roles = current_user.roles.pluck(:role)

    if roles.include?('admin')
      can :read, :all
      can [:acknowledge_bug], Bug
      can :manage, [Admin, User]

      can [:list_research, :list_escalations], Bug #legacy
    end

    if roles.include?('manager')
      can :manage, User do |user|
        user.ancestors.include?(current_user)
      end
    end

    if roles.include?('escalator')
      can :manage, EscalationBug
      can :manage, [Attachment, Note]
      can :publish_to_bugzilla, Note
      can :update_preferences, User, id: current_user.id
    end

    if roles.include?('committer')
      can [:manage, :acknowledge_bug, :toggle_liberty], ResearchBug
      can :manage, [Attachment, Note, Rule, RuleDoc, Exploit, Reference]
      can :publish, Rule
      can :publish_to_bugzilla, Note
      can :update_preferences, User, id: current_user.id
    end

    if roles.include?('analyst')
      can [:manage, :acknowledge_bug], ResearchBug
      can :manage, [Attachment, Note, Rule, RuleDoc, Exploit, Reference]
      can :publish_to_bugzilla, Note
      can :toggle_liberty, ResearchBug do |bug|
        bug.liberty_clear?
      end
      can :update_preferences, User, id: current_user.id
    end

    if roles.include?('build coordinator')
      cannot [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
      can :read, [ResearchBug, Attachment, Note, Rule, RuleDoc, Exploit, Reference]
      can :update_preferences, User, id: current_user.id
    end
  end
end
