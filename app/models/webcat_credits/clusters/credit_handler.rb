class WebcatCredits::Clusters::CreditHandler
  attr_reader :user, :cluster

  def initialize(user, cluster)
    @user = user
    @cluster = cluster
  end

  def handle_pending_credit
    clear_previous_user_credits
    create_credit_for(WebcatCredit::PENDING)
  end

  def handle_unchanged_credit
    clear_previous_user_credits
    create_credit_for(WebcatCredit::UNCHANGED)
  end

  def handle_fixed_credit
    clear_previous_user_credits
    create_credit_for(WebcatCredit::FIXED)
  end

  private

  def clear_previous_user_credits
    ClusterCredit.where(user: user, domain: cluster[:domain]).destroy_all
  end

  def create_credit_for(credit_type)
    ClusterCredit.create(
      user: user,
      domain: cluster[:domain],
      credit: credit_type
    )
  end
end
