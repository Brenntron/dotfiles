module BugsHelper

  def allowed_editors(bug)
    User.all.reject { |u| u.id == bug.committer_id }
  end

  def allowed_committers(bug)
    User.with_role('committer').reject { |u| u.id == bug.user_id }
  end
end