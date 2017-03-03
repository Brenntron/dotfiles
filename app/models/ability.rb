class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.has_role?('admin')
      can :manage, :all
    elsif user.has_role?('manager')
      can :manage, :all
      cannot :publish, Rule
    elsif user.has_role?('committer')
      can :read, :all
      can [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
      can :publish, Rule
      can :publish_to_bugzilla, Note
    elsif user.has_role?('analyst')
      can :read, :all
      can [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
      can :publish_to_bugzilla, Note
      cannot :publish, Rule
    elsif user.has_role?('build coordinator')
      can :read, :all
      cannot [:update, :destroy, :create], [Bug, Rule, Attachment, Note, Exploit, Reference]
    else
      can :read, :all
    end
  end
end