class Ability
  include CanCan::Ability

  def initialize(user_given)
    current_user = user_given || User.new

    can :read, :all

    if current_user.has_role?('admin')
      can :manage, User
    end
    if current_user.has_role?('manager')
      can :manage, User do |user|
        user.ancestors.include?(current_user)
      end
      cannot :publish, Rule
    end
    if current_user.has_role?('committer')
      can [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
      can :publish, Rule
      can :publish_to_bugzilla, Note
    end
    if current_user.has_role?('analyst')
      can [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
      can :publish_to_bugzilla, Note
      cannot :publish, Rule
    end
    if current_user.has_role?('build coordinator')
      cannot [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
    end
  end
end
