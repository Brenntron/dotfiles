class WebcatCredits::InternalCategorizations::CreditHandler
  attr_reader :user, :domain

  def initialize(user, domain)
    @user = user
    @domain = domain
  end

  def handle_internal_credit
    clear_previous_user_credits
    create_credit_for(WebcatCredit::INTERNAL)
  end

  private

  def clear_previous_user_credits
    InternalCategorizationCredit.where(user: user, domain: domain).destroy_all
  end

  def create_credit_for(credit_type)
    InternalCategorizationCredit.create(
      user: user,
      domain: domain,
      credit: credit_type
    )
  end
end
